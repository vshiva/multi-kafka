#!/usr/bin/env python

import sys

from string import Template

def main(argv):
    if len(argv) < 2:
        print 'config.py <config> <hostname>'
        sys.exit()

    config = argv[0]
    template = open( "{0}.template".format(config) )
    s = Template( template.read() )

    output = open(config, "w")
    output.write(s.safe_substitute(kafka_hostname = argv[1]))
    output.close()

if __name__ == "__main__":
   main(sys.argv[1:])
