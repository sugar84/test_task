#!/usr/bin/env perl
use Dancer;
use lib path(dirname(__FILE__), 'lib');
load_app 'test_task';
dance;
