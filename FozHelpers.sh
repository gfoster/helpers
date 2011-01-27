# File: Helpers.sh
# Author: Gary D. Foster <gary.foster@gmail.com>
# Created: 5/12/2010

# A set of bash functions to maintain a global progress log array called
# TASK_LOG.
#
# Each entry in TASK_LOG[] will contain one task in the format:
# <task name>\t<status>\t<percent complete>\t<start time>\t<end time>
#
# TASK_LOG will exist in the global namespace, so assume anything you
# have there will be assimilated.  You have been warned.  There shouldn't
# be any other namespace pollution.
#
# We start our index at one instead of zero so we can store a current
# task pointer in the zero index
#
# The saveLog format *should* be compatible with the ruby and python versions
#
# An example usage might be:
#
# progress=$(getProgressLogName)
#
# addLogEntry "task one"
# addLogEntry "task two"
# addLogEntry "task three"
#
# startLog
# saveLog "$progress"
# <do some stuff for task one>
# nextLogEntry
# saveLog "$progress"
# <do some stuff for task two>
# nextLogEntry
# saveLog "$progress"
# <do some more stuff for task three>
# finishLog
# saveLog "$progress"

# alternatively you could do a "nextLogEntry" again at the last task
# and it will automatically reset, finishLog will cycle through and mark
# all remaining tasks as complete.  As a style issue, I recommend calling
# finishLog on your last entry instead of nextLogEntry so it's crystal
# clear that you know you are done.
#
# Betcha didn't think you could do this kind of stuff in bash, didja?

function getProgressLogName {
   echo "/opt/nodeagent/handlers/state/$(basename $0 | sed -e 's/^\(.*\)\.template\..*$/\1.status/')"
}

function addLogEntry {
   local entry=$1
   local status="pending"
   local percent=0
   local start=""
   local end=""
   
   entry="${entry}\t${status}\t${percent}\t${start}\t${end}"
   
   if (( ${#TASK_LOG[@]} == 0 )); then
      TASK_LOG=( 0 "${entry}" )
   else
      local index=${#TASK_LOG[@]}
      TASK_LOG[${index}]="${entry}"
   fi
}

function clearLog {
   unset TASK_LOG
}

function printLog {
   local i
   local num_entries=$(( ${#TASK_LOG[@]} - 1 ))

   for (( i=1; i<=$num_entries; i++ )); do
      echo -e ${TASK_LOG[${i}]}
   done
}

function saveLog {
   local filename=$1
   
   if [ -z ${#TASK_LOG[@]} ]; then
      return
   fi
   
   if [ -z "$filename" ]; then
      return
   fi
   
   echo ${TASK_LOG[0]} > ${filename}
   printLog >> ${filename}
}

function loadLog {
   return
}

function startLog {
   local num_entries=$(( ${#TASK_LOG[@]} - 1 ))
   
   if (( num_entries < 1 )); then
      return
   fi
   
   let TASK_LOG[0]=1
   startLogEntry
}

function startLogEntry {
   # This assumes you are using a GNU version of sed (linux boxes) for the -r extended regexp switch
   # and won't work on non-GNU versions of sed (i.e. the stock Mac OSX sed)
   
   local current_task=${TASK_LOG[${TASK_LOG[0]}]}
   
   TASK_LOG[${TASK_LOG[0]}]=$(echo -e "$current_task" | sed -r "s/^(.*)\t(.*)\t(.*)\t(.*)\t(.*)$/\1\\\tactive\\\t\3\\\t$(timestamp)\\\t\5/")
}

function finishLogEntry {
   # This assumes you are using a GNU version of sed (linux boxes) for the -r extended regexp switch
   # and won't work on non-GNU versions of sed (i.e. the stock Mac OSX sed)
   
   local current_task=${TASK_LOG[${TASK_LOG[0]}]}
   
   TASK_LOG[${TASK_LOG[0]}]=$(echo -e "$current_task" | sed -r "s/^(.*)\t(.*)\t(.*)\t(.*)\t(.*)$/\1\\\tcomplete\\\t100\\\t\4\\\t$(timestamp)/") 
}

function failLogEntry {
   # This assumes you are using a GNU version of sed (linux boxes) for the -r extended regexp switch
   # and won't work on non-GNU versions of sed (i.e. the stock Mac OSX sed)
   
   local current_task=${TASK_LOG[${TASK_LOG[0]}]}
   
   TASK_LOG[${TASK_LOG[0]}]=$(echo -e "$current_task" | sed -r "s/^(.*)\t(.*)\t(.*)\t(.*)\t(.*)$/\1\\\tfailed\\\t\3\\\t\4\\\t$(timestamp)/")
}

function abortLog {
   failLogEntry
   TASK_LOG[0]=0
}

function finishLog {
   local i
   local num_entries=$(( ${#TASK_LOG[@]} - 1 ))
   local ptr=${TASK_LOG[0]}
   
   for (( i=$ptr; i<=$num_entries; i++ )); do
      nextLogEntry
   done
}

function nextLogEntry {
   local num_entries=$(( ${#TASK_LOG[@]} - 1 ))
   local ptr=${TASK_LOG[0]}

   # Three cases:
   # case 1: task list is empty or unstarted
   # case 2: task list is ongoing and we are not on the last entry
   # case 3: task list is ongoing, we are currently on the last entry
   
   # this is case 1
   if (( ptr < 1 )); then
      # can't advance an unstarted task list
      # so we just politely ignore this request
      return
   fi
   
   finishLogEntry
   (( TASK_LOG[0]++ ))
   
   if (( ${TASK_LOG[0]} <= num_entries )); then
      # this is case 2
      startLogEntry
   else
      # this is case 3
      TASK_LOG[0]=0
   fi
}

# return a timestamp in iso8601 format
# call with: foo=$(timestamp)

function timestamp {
   echo $(date +%FT%T.%NZ)
}