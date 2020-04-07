#!/usr/bin/env python

'''
Rationale: autopep8 will not remove line breaks inside statements, but
sometimes they are not needed and it's time consuming to remove them
manually.

This script will remove line breaks inside statements. The result should
be run through autopep8 for formatting. Empty lines are preserved, as
autopep8 can deal with them and they are trivial to remove in any editor.
'''

from __future__ import absolute_import, division, print_function
import argparse


class ParsedLine(object):
    '''Line representation'''

    tabsize = 8

    def __init__(self, line):
        self.continuation = line.endswith('\\')
        line = line.rstrip('\\')
        line = line.rstrip()
        if not line:
            self.indent = 0
            self.core = ''
        else:
            self.indent = self.visible_indent(line)
            self.core = line.lstrip()

    @classmethod
    def visible_indent(cls, line):
        '''Calculate visible indent of a line'''
        pos = 0
        for char in line:
            if char == '\t':
                pos = cls.tabsize * (pos // cls.tabsize + 1)
            elif str.isspace(char):
                pos += 1
            else:
                break
        return pos

    def is_empty(self):
        '''True if the line is empty after trimming'''
        return self.core == ''

    def is_block_start(self):
        '''True if a block with wider indent is expected next'''
        return self.core.endswith(':')

    def is_appendable(self, stmt):
        '''True if self can be appended to the statement'''
        if not stmt:
            return True
        if self.is_empty():
            return False

        prev_line = stmt[0]
        if prev_line.is_empty():
            return False
        if prev_line.is_block_start():
            return False

        first_line = stmt[0]
        if first_line.indent >= self.indent:
            return False
        return True


class Unbreak(object):
    '''Remove line breaks in Python code'''

    def __init__(self):
        pass

    @staticmethod
    def parse_data(data_in):
        '''Read and process data from file'''

        statements = []
        statement = []
        for line in data_in.splitlines():
            pline = ParsedLine(line)

            if pline.is_appendable(statement):
                statement.append(pline)
            else:
                statements.append(statement)
                statement = [pline]

        if statement:
            statements.append(statement)

        return statements

    @staticmethod
    def write_statement(statement):
        '''Write a statement, possibly merge lines'''

        out = ''
        if not statement:
            return
        pline = statement[0]
        out += pline.indent * ' ' + pline.core
        for pline in statement[1:]:
            out += ' ' + pline.core
        out += '\n'
        return out

    def write_data(self, statements):
        '''Write data'''
        out = ''
        for statement in statements:
            out += self.write_statement(statement)
        return out

    def process(self, data):
        '''Process file'''
        statements = self.parse_data(data)
        return self.write_data(statements)

    @staticmethod
    def parse_options():
        '''Parse command line options'''

        parser = argparse.ArgumentParser(
            description='Remove line breaks in Python code')
        parser.add_argument('--in-place', action='store_true',
                            help='Replace the file')
        parser.add_argument('input', help='Source file to process')
        parser.add_argument('output', nargs='?', help='Output file')

        args = parser.parse_args()
        if args.in_place and args.output:
            parser.error('Cannot use --in-place with output file')

        return args

    def run(self):
        '''Main function'''

        args = self.parse_options()

        if args.output:
            newfile = args.output
        elif args.in_place:
            newfile = args.input
        else:
            newfile = args.input + '.unbreak'

        with open(args.input, 'r') as fd_in:
            data_in = fd_in.read()

        data_out = self.process(data_in)

        with open(newfile, 'w') as fd_out:
            fd_out.write(data_out)


if __name__ == '__main__':
    Unbreak().run()
