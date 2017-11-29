#!/usr/bin/env python
# -*- coding: utf-8 -*-

import re
import sys
import time

activity_re=re.compile('^\*+ ([^:]*) *:(.*):$')
date_re="[0-9]{4}-[0-9]{2}-[0-9]{2} .. [0-9]{2}:[0-9]{2}"
time_fmt="%Y-%m-%d %H:%M"
clock_re=re.compile('^ *CLOCK: \[(%s)\](--\[(%s)\] => .*$)?' % (date_re, date_re))
type_re=re.compile('(Freizeit|Daily|Recurring|ARCHIVE|:?)')

def mangle_type(activity_type):
    activity_type = type_re.sub("", activity_type)
    if activity_type == "Morgen_Abend":
        activity_type = "Morgen/Abend"
    return activity_type

def match_activity(line, current):
    match = activity_re.match(line)
    if match:
        activity = match.group(1).strip()
        activity_type = mangle_type(match.group(2))
        if type:
            return (activity, activity_type)
    return current

def match_clock(line):
    match = clock_re.match(line)
    if match:
        (start, end) = match.group(1, 3)
        if not end:
            end = time.strftime("%Y-%m-%d XX %H:%M")
        return (start, end)
    return None

def strip_day(date):
    return date[:11] + date[14:]

def set_time(original, hour, minute):
    o = original
    return time.localtime(time.mktime([o.tm_year, o.tm_mon, o.tm_mday, hour, minute, 0, o.tm_wday, o.tm_yday, o.tm_isdst]))

def split_days(clock):
    (start, end) = clock
    start = strip_day(start)
    end = strip_day(end)
    start_ts = time.strptime(start, time_fmt)
    end_ts = time.strptime(end, time_fmt)
    if start_ts.tm_mday != end_ts.tm_mday:
        start_1 = start_ts
        end_1 = set_time(start_ts, 23, 59)
        start_2 = set_time(end_ts, 0, 0)
        end_2 = end_ts
        return [ ( time.strftime(time_fmt, start_1), time.strftime(time_fmt, end_1) ),
                 ( time.strftime(time_fmt, start_2), time.strftime(time_fmt, end_2) ) ]
    else:
        return [ (start, end) ]

if len(sys.argv) < 3:
  print 'Usage: %s <input-file> <output-file>' % sys.argv[0]
  sys.exit(1)

input_filename = sys.argv[1]
output_filename = sys.argv[2]
infile = open(input_filename, 'rb')
outfile = open(output_filename, 'w')

print >> outfile, "\t".join(['Activity', 'ActivityType', 'Start', 'End'])
activity = None
activity_type = None
for line in infile:
    (activity, activity_type) = match_activity(line, (activity, activity_type))
    clock = match_clock(line)
    if clock:
        for (start, end) in split_days(clock):
            print >> outfile, "\t".join([str(x) for x in [activity, activity_type, start, end]])
