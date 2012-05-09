import os
from setuptools import setup

def read(fname):
    return open(os.path.join(os.path.dirname(__file__), fname)).read()

setup(
    name = "fozhelpers",
    version = "0.2",
    author = "Gary Foster",
    author_email = "gary.foster@gmail.com",
    description = ("a set of utility functions"),
    license = "MIT",
    keywords = "utility functions methods",
    url = "http://github.org/gfoster/helpers",
    packages=['fozhelpers', 'tests'],
    long_description=read('README'),
    classifiers=[
        "Development Status :: 5 - Production/Stable",
        "Topic :: Utilities",
        "License :: OSI Approved :: MIT License",
    ],
)
