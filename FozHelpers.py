"""
Summary: General purpose utility functions (not project specific)
"""

import datetime
import feedparser
import grp
import httplib
import logging
import logging.handlers
import os
import pickle
import pwd
import re
import sys
import time
import traceback
import urllib
import urllib2

from urlparse import urlparse

class Struct(object):
    "Python doesn't have a struct class, so we will fake one"
    
    def __init__(self, **entries):
        self.__dict__.update(entries)
        
    def __repr__(self):
        args = ['%s=%s' % (k, repr(v)) for (k,v) in vars(self).items()]
        return '%s(%s)' % (self.__class__.__name__, ', '.join(args))

class Task(object):
    def __init__(self, name='', status='pending', percent=0, startTime='', endTime=''):
        self.name      = name
        self.status    = status
        self.percent   = percent
        self.startTime = startTime
        self.endTime   = endTime
        
    def __repr__(self):
        args = ['%s=%s' % (k, repr(v)) for (k,v) in vars(self).items()]
        return '%s(%s)' % (self.__class__.__name__, ', '.join(args))

    def __str__(self):
        return "%s\t%s\t%s\t%s\t%s" % (self.name, self.status, self.percent, self.startTime, self.endTime)
        
    def start(self):
        "Mark the current task as active"
        self.status = 'active'
        self.startTime = generateIso8601Date()
        
    def finish(self):
        "Mark the task as complete"
        self.status = 'complete'
        self.percent = 100
        self.endTime = generateIso8601Date()
        
    def fail(self):
        "Mark the task as failed"
        self.status = 'failed'
        self.endTime = generateIso8601Date()
        
    def clear(self):
        "Clear the and set it to pending"
        self.status    = 'pending'
        self.percent   = 0
        self.startTime = ''
        self.endTime   = ''
        

class Tasklist(object):
    def __init__(self, filename=None):
        self._tasks = []
        self._currentTask = -1
        self.filename = filename
        self.__status = 0
        
    def __iter__(self):
        for index in range(0, len(self._tasks), 1):
            yield self._tasks[index]
            
    def __repr__(self):
        args = ['%s=%s' % (k, repr(v)) for (k,v) in vars(self).items()]
        return '%s(%s)' % (self.__class__.__name__, ', '.join(args))
        
    def __str__(self):
        res = ""
        for task in self:
            res += str(task)+"\n"
        res=res[:-1]
        return res    
        
    def _getStatus(self):
        return self.__status
                
    def add(self, task):
        "Add a task object to the queue"
        
        argType = type(task).__name__
        
        if argType == 'str':
            self._tasks.append(Task(task))
        elif argType == 'Task':
            self._tasks.append(task)
        else:
            raise ValueError, "Can only add tasks to tasklist"
            
        return self
        
    def delete(self, taskNumber=None):
        "Delete a task from the queue (no task number passed in means delete the current task)"
        if taskNumber is None:
            taskNumber = self._currentTask
            
        if isBlank(self._tasks):
            raise ValueError, "Attempt to delete empty task"
            
        if taskNumber > len(self._tasks) - 1 or taskNumber < 0:
            raise ValueError, "attempt to delete invalid task"
            
        if taskNumber == self._currentTask:
            self.next()
            self._currentTask -= 1
            
        del(self._tasks[taskNumber])
        self.save()
        
        self.__status = int(float(self._currentTask) / len(self._tasks) * 100)
        
        return self
        
    def next(self):
        "Mark the current task as complete and advance the task counter"
        if self._currentTask >= 0:
            self._tasks[self._currentTask].finish()
            
        self._currentTask += 1
        
        if self._currentTask < len(self._tasks):
            self.__status = int(float(self._currentTask) / len(self._tasks) * 100)
            self._tasks[self._currentTask].start()
        else:
            self._currentTask = -1
            
        self.save()
            
    def finish(self):
        "Mark all remaining tasks complete and halt the queue"
        if self._currentTask == -1:
            return
            
        for index in range(self._currentTask, len(self._tasks), 1):
            self.next()
            
        self.__status = 100
        
        self.save()
            
    def abort(self):
        "Fail the current task and halt the queue by setting the task pointer to None"
        if self._currentTask < 0:
            self._currentTask = 0
            
        self._tasks[self._currentTask].fail()
        self._currentTask = -1
        self.save()
        
        return self
            
    def start(self):
        "Reset all the tasks in the queue to pending and move the task pointer to the beginning"
        # clear out the task list status flags and times on a start
        for index in range(0, len(self._tasks), 1):
            self._tasks[index].clear()
            
        self._currentTask = 0
        self._status = 0
        self._tasks[self._currentTask].start()
        self.save()
        
        return self
        
    def currentTask(self):
        "Return the current task object being worked on"
        if self._currentTask < 0:
            return None
        else:
            return self._tasks[self._currentTask]
            
    def save(self, filename=None):
        "Marshal ourselves to a file"
        if filename is None:
            filename = self.filename
            
        if filename is not None:
            contents = str(self._currentTask) + "\n"
            contents += str(self)
            fd = open(filename, 'w').write(contents)
            
            return self

    def load(self, filename=None):
        "Demarshal ourselves from a previously saved file"
        if filename is None:
            filename = self.filename
            
        if filename is not None:        
            fd = open(filename, 'r')
            vals = fd.readlines()
            fd.close()
            # now strip all the trailing newlines
            vals = map(lambda x: x.rstrip("\n"), vals)
            self.clear()
            # First line is the task pointer
            self._currentTask = int(vals.pop(0))
            # rest of vals contains the individual task
            for task in vals:
                (name, status, percent, startTime, endTime) = task.split("\t")
                self.add(Task(name=name, status=status, percent=percent, startTime=startTime, endTime=endTime))
            
    def clear(self):
        "Empty out the task list"
        self._tasks = []
        self._currentTask = -1
        
        return self
        
    status = property(lambda self: self._getStatus())
    
def setupLogging(logfile="./logfile.log", loglevel=logging.INFO, stdout=False, syslog=False, when='midnight', interval=1, backupCount=6):
    """
    Set up the logging service.  Returns a log object.  Set stdout and syslog to True to add add'l streams.
    Defaults to a timed rotating log file rotating daily at midnight with 6 backup copies.
    
    You can write to the log object with log.<level>("message").  Valid levels are (debug|info|warning|error|critical)
    """

    log = logging.getLogger(logfile)

    log.setLevel(loglevel)
    formatter = logging.Formatter('[%(asctime)-12s] %(levelname)-8s <%(module)s#%(funcName)s:%(lineno)s> %(message)s')

    # logging.handlers.RotatingFileHandler(filename, mode, maxBytes, backupCount, encoding) can be used for rotating based on file size
    filelog = logging.handlers.TimedRotatingFileHandler(logfile, when=when, interval=interval, backupCount=backupCount)
    filelog.setFormatter(formatter)

    log.addHandler(filelog)
    
    if syslog:
        sl = logging.handlers.SysLogHandler(('localhost',514))
        sl.setFormatter(formatter)
        log.addhandler(sl)
        
    if stdout:
        so = logging.StreamHandler(sys.stdout)
        so.setFormatter(formatter)
        log.addHandler(so)

    return log

def isBlank(arg):
    argType = type(arg).__name__
    
    
    if argType == 'str':
        return True if len(arg.strip()) == 0 else False
    elif argType == 'list' or argType == 'dict':
        return True if len(arg) == 0 else False
    elif argType == 'NoneType':
        return True
    else:
        raise ValueError, "illegal type: %s" % (argType)
        
def fetchRemoteFile(url, localFile=None, permissions=None, owner=None, group=None, retries=0):
    "Fetch a remote file and either write it to a local file or return it"
    # if token:
    #     cookie = "iPlanetDirectoryPro=%s" % (token)
    # else:
    #     cookie = None
    while retries > -1:
        try:
            if localFile:
                contents = urllib.URLopener()
                # if cookie:
                #     contents.addheader('Cookie', cookie)
                contents.retrieve(url, localFile)
                contents.close()
                if permissions:
                    os.chmod(localFile, permissions)
                if owner or group:
                    chown(localFile, owner=owner, group=group)
                return
            else:
                request = urllib2.Request(url)
                if cookie:
                    request.add_header('Cookie', cookie)
                response = urllib2.urlopen(request)
                fileContents = response.read()
                actualUrl = response.geturl()
                if actualUrl != url:
                    raise IOError, ('http error',302, "resource was redirected")
                response.close()
                return fileContents
        except Exception, e:
            # Ignore exceptions, we will throw an exception if retries
            # are exceeded only
            if retries != 0:
                retries -= 1
                pass
            else:
                raise

def formatExcPlus(exc_info):
    """
    Return descriptive exception info, including all locals, frame info and traceback.
    Pass this method an exc_info object and it will pretty print an entire stack trace
    with values of every local variable in scope at each stack level.
    """    
    (type_, value_, tb) = exc_info
    
    tb_info = "Exception type: %s\nValue: %s\n\nTraceback Info:\n" % (type_, value_)
    
    tb_info += "".join(traceback.format_tb(tb))
    tb_info += "\n"
    
    while True:
        if not tb.tb_next:
            break
        tb = tb.tb_next
    stack = []
    f = tb.tb_frame
    while f:
        stack.append(f)
        f = f.f_back
    stack.reverse()

    tb_info += "Locals by frame, innermost last\n"
    for frame in stack:
        tb_info += "\n"
        tb_info += "Frame %s in %s at line %s\n" % (frame.f_code.co_name,
            frame.f_code.co_filename, frame.f_lineno)
        for key, value in frame.f_locals.items():
            tb_info += "\t%20s = " % (key)
            try:
                tb_info += "%s\n" % (str(value))
            except:
                tb_info += "<ERROR WHILE PRINTING VALUE>\n"
    return tb_info
                
def grep(string,list,opt=''):
    "search a list for a substring.  Pass -v as an option to return everything BUT the match"
    
    expr = re.compile(string)
    if opt=='-v':
        nexpr = lambda x: expr.search(x) == None
        return filter(nexpr,list)
    return filter(expr.search,list)

def timestamp():
    return datetime.datetime.today().strftime("%D %T")
        
def generateDate(offsetDays=0):
    "alias function for generateHttpDate"
    return generateHttpDate(offsetDays)
    
def generateHttpDate(offsetDays=0):
    "Generate an httpdate formatted date string, offsetDays from now (in UTC/GMT)."
    return (datetime.datetime.utcnow() + datetime.timedelta(days=offsetDays)).strftime('%a, %d %b %Y %T GMT')

def generateIso8601Date(offsetDays=0):
    "Generate an ISO-8601 formatted date string in UTC, offsetDays from now yyyy-mm-dd'T'HH:MM:SS.fff'Z'."
    
    return (datetime.datetime.utcnow() + datetime.timedelta(days=offsetDays)).isoformat()+"Z"
    
def generateInternetTime():
    "Generate a timestamp in internet time format (beats)"
    t =  datetime.datetime.utcnow() + datetime.timedelta(seconds=3600) # Biel, Switzerland
    midnight = datetime.datetime(year=t.year, month=t.month, day=t.day)
    secs = (t - midnight).seconds
    beats = int(secs/86.4)
    return beats

def writeFile(filename, contents='', owner=None, group=None, permissions=None, append=False):
    # os.chmod() second param is OCTAL
    # python automatically converts 0644 from octal into decimal
    
    close = False
    
    if type(filename).__name__ == "str":
        # we got passed a filename to create
        if append:
            mode = "a"
        else:
            mode = "w"
            
        fd = open(filename, mode)
        name = fd.name
        # if we create the file, we close it, otherwise we leave it open
        close = True
    elif type(filename).__name__ == "file":
        # we got passed an open file descriptor
        fd = filename
        name = fd.name
    elif type(filename).__name__ == 'instance' and type(filename.file).__name__ == 'file':
        # we got passed a temporary file instance created by the tempfile module
        # which isn't 'quite' the same as a normal FD although it acts like one
        fd = filename
        name = filename.name
    else:
        raise TypeError, "filename must be a file object or a filename (string)"
        
    fd.write(contents)
    
    if close:
        fd.close()

    if permissions:
        os.chmod(name, permissions)
        
    if owner or group:
        chown(name, owner, group)

def chown(filename, owner=None, group=None):
    # -1 to chown means don't change it
    
    uid = pwd.getpwnam(owner).pw_uid if owner else -1
    gid = grp.getgrnam(group).gr_gid if group else -1

    os.chown(filename, uid, gid) 

def getEc2PublicHostName():
    return fetchRemoteFile("http://169.254.169.254/2009-04-04/meta-data/public-hostname")
    
#####
##### SSO Methods
#####

def getSSOToken(uri, username, password):
    """
    Attempt to retrieve a valid token from an SSO server.
    Pass in the base URI to the sso realm (e.g. http://ssoserver.foo.com/opensso)
    and the username and password.  Returns None if invalid login
    """
    
    uri += "/identity/authenticate?username=%s&password=%s" % (username, password)
    
    try:
        req = urllib2.Request(uri)
        response = urllib2.urlopen(req)
        body = response.read()
        token = body.split('=', 1)[1].rstrip("\n")
    except urllib2.HTTPError, e:
        if e.code == 401:
            # Invalid login
            return None
        else:
            raise
    else:
        return token

def verifySSOToken(uri, token):
    "Attempt to verify a token against a base SSO uri"
    
    uri += "/identity/isTokenValid"

    data = urllib.urlencode({'tokenid': token})

    try:
        req = urllib2.Request(uri, data)
        response = urllib2.urlopen(req)
        page = response.read()
    except urllib2.HTTPError, e:
        if e.code == 401:
            valid=False
        else:
            raise
    else:
        body = page.split("=", 1)[1].rstrip("\n")
        if body.lower() == 'true':
            valid = True
        else:
            valid = False

    return valid
    
def invalidateSSOToken(uri, token):
    "Logout and invalidate a previously generated token"
    
    uri += "/identity/logout"

    data = urllib.urlencode({'subjectid': token})

    try:
        req = urllib2.Request(uri, data)
        response = urllib2.urlopen(req)
    except urllib2.HTTPError, e:
        return e.code
    else:
        return response.code

def authorizeSSOResource(uri, token, action):
    "Determine if given action is authorized to token at uri"

    uri += "/identity/authorize"

    if action.upper() in ['GET', 'PUT', 'POST', 'DELETE', 'OPTIONS', 'HEAD']:
        try:
            data = urllib.urlencode({'uri': uri, 'action': action.upper(), 'subjectid': token})
            req = urllib2.Request(uri, data)
            response = urllib2.urlopen(req)
            page = response.read()
        except urllib2.HTTPError, e:
            valid = False
        else:
            body = page.split("=", 1)[1].rstrip("\n")
            if body.lower() == 'true':
                valid = True
            else:
                valid = False
    else:
        raise ValueError, "Action must be one of GET/POST/PUT/DELETE/OPTIONS/HEAD"

    return valid
    
def urlEscape(uri):
    "Properly escapes a URI string and returns the escaped version"
    
    return urllib.quote(urllib.unquote(uri), safe=":/")

def installPackage(packages):
    "accepts either a list or a single package and installs it"
    
    if type(packages).__name__ == 'str':
        packages = [packages]
        
    for pkg in packages:
        rc = runCmd("! /usr/bin/yum install -y --nogpgcheck %s | egrep '^No package .+ available\.' 2>&1 >/dev/null " % (pkg))
        if rc:
            # if we get an error, exit prematurely
            return rc
            
def writeTaskProgress(filename, caller, taskName, percentComplete, startTime=generateIso8601Date()):
    fd = open(filename, "a")
    fd.write("%s\t%s\t%s\t%s\t%s\n" % (generateIso8601Date(), caller, percentComplete, startTime, taskName))
    fd.close()

def getProgressLogName():
    me = os.path.basename(sys.argv[0])
    me = "/opt/nodeagent/handlers/state/" + re.sub(r'.template.*$', '', me) + ".status"
    return me
    
def exitIf(rc):
    if rc != 0:
        sys.exit(rc)

def runCmd(command, ignoreRC=True, asUser=None):
    if asUser:
        # Need to escape any double quotes
        if command.find('"') != -1:
            command = command.replace('"', '\\"')
        command = "/sbin/runuser -s /bin/bash - %s -c \"%s\"" % (asUser, command)
        
    rc = os.system(command)
    if not ignoreRC and rc:
        raise OSError, "%s returned a non-zero RC: %d" % (command, rc)
    else:
        return rc
        
def addUser(username, uid=None, group=None, shell=None, homeDir=None, createHome=False):
    cmd = "/usr/sbin/useradd "
    cmd += "-u %d" % (uid) if uid else " "
    cmd += "-g %s" % (group) if group else " "
    cmd += "-s %s " % (shell) if shell else " "
    cmd += "-d %s " % (homeDir) if homeDir else " "
    cmd += "-m " if createHome else "-M "
    cmd += username
    
    rc = runCmd(cmd)
    return rc

def addGroup(groupname, gid=None):
    cmd = "/usr/sbin/groupadd "
    cmd += "-g %d" % (gid) if gid else " "
    cmd += groupname
    
    rc = runCmd(cmd)
    return rc

def setPassword(username, password):
    cmd = "echo '%s' | /usr/bin/passwd --stdin %s" % (password, username)
    rc = runCmd(cmd)
    return rc
    
def removeTimestamp(filename):
    # Remove timestamp added by webresource , e.g 2011-01-25T13-31-20-latest.tar.gz
    import re
    tsPattern=r'^(19|20)\d\d[- / .](0[1-9]|1[012])[- / .](0[1-9]|[12][0-9]|3[01])T(0[0-9]|1[0-9]|2[0-4])[- / .](0[0-9]|1[0-9]|2[0-9]|3[0-9]|4[0-9]|5[0-9]|60)[- / .](0[0-9]|1[0-9]|2[0-9]|3[0-9]|4[0-9]|5[0-9]|60)-'
    
    return re.sub(tsPattern, '', filename)
    
