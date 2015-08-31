#!/usr/bin/env python

import subprocess
import unittest
import os
import sys
import platform

class BashFunctionCaller(object):
    def __init__(self, script):
        self.script = script

    def __getattr__(self, name):
            '''allows to do caller.FUNC_NAME(ARGS)'''
            def call_fun(*args):
                script_path = "'{}'".format(os.path.join(os.path.dirname(__file__), self.script))
                return subprocess.check_output(
                        ['bash', '-c', 'source {} && {} {}'.format(script_path, name, " ".join(args))],
                        universal_newlines=True)
                
            return call_fun
       

# inspired by https://github.com/bernardpaulus/bash_unittest
 
class PFCTest(unittest.TestCase):
    def setUp(self):
        self.script = BashFunctionCaller("../cervidae_funcs.sh")
        self.output = self.script.preflight_checklist()
        self.is_64bit = sys.maxsize > 2**32
        self.is_32bit = sys.maxsize > 2**16 and not sys.maxsize > 2**32
        self.is_unknownbit = not self.is_32bit and not self.is_64bit

    def test_platform(self):
        if self.is_64bit:
            self.assertIn("x64", self.output)
        elif self.is_32bit:
            self.assertIn("x86", self.output)
        elif self.is_unknownbit:
            self.assertIn("Unrecognizable architecture", self.output)
        else:
            self.assertRaises(RuntimeError)

    def test_java(self):
        java_out = subprocess.check_output(["java", "-version"])
        if len(java_out) == 0:
            self.assertIn("Java not found", self.output)
        
    def test_pfc_complete(self):
        self.assertIn("Complete", self.output)


class DirectoryTest(unittest.TestCase):
    def setUp(self):
        self.script = BashFunctionCaller("../cervidae_funcs.sh")
        self.pf = self.script.preflight_checklist()
        self.output = self.script.setup_directories()

    def test_directories(self):
        self.assertTrue(os.path.isdir("bin"))
        self.assertTrue(os.path.isdir("etc/kibana/conf"))
        self.assertTrue(os.path.isdir("etc/kibana/plugins"))
        self.assertTrue(os.path.isdir("etc/logstash/conf"))
        self.assertTrue(os.path.isdir("etc/logstash/patterns"))
        self.assertTrue(os.path.isdir("etc/elasticsearch/conf"))
        self.assertTrue(os.path.isdir("etc/elasticsearch/plugins"))
        self.assertTrue(os.path.isdir("lib"))
        self.assertTrue(os.path.isdir("logs"))
        self.assertTrue(os.path.isdir("share"))
        self.assertTrue(os.path.isdir("tmp"))
        self.assertTrue(os.path.isdir("var/run"))
        self.assertTrue(os.path.isdir("packages"))
