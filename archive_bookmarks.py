#!/usr/bin/env/python3

#
# Archive important data in bookmarks
#

import json
import os.path
import re
import subprocess
import sys

CHROMIUM_BOOKMARKS = os.path.expanduser("~/.config/chromium/Default/Bookmarks")
COMPLETED_FILE = os.path.expanduser("~/.archive_bookmarks_completed")
YOUTUBE_URL_REGEX = re.compile("https*://www\.youtube\.com/watch\?v=[^\"&]+")
YOUTUBE_ARCHIVE_COMMAND = os.path.expanduser("~/bin/archive_youtube")

class ArchiveBookmarks:
    def __init__(self):
        pas


class Bookmarks:
    def __init__(self, filename):
        with open(filename) as f:
            self.raw_data = f.read()
            #self.data = json.load(f)

    def archive_youtube(self, test_p, callback=lambda _: None):
        """
        Archive all URLs satisfying test_p
        Call callback on each URL sucessfully archived
        """
        for url in self._youtube_urls():
            if test_p(url):
                command = '{0} "{1}"'.format(YOUTUBE_ARCHIVE_COMMAND, url)
                try:
                    ret = subprocess.call(command, shell=True)
                except OSError as e:
                    print("Command failed: {0}".format(command))
                    print(e)
                    exit(1)
                callback(url)

    def _youtube_urls(self):
        return YOUTUBE_URL_REGEX.findall(self.raw_data)

    def _traverse(self, test_p, root=None):
        """
        Traverse the bookmarks, returning a list of objects
        satisfying the predicate test_p(bookmark_dict)
        TODO: stack overflow by recursion
        """
        pass
        # global bookmark_objects # avoid stack overflow
        # root = root or self.data

        # if type(root) == dict:
        #     print("dict")
        #     if 'url' in root:
        #         print("URL")
        #         if test_p(root):
        #             bookmark_objects.append(root)
        #     for k in root:
        #         bookmark_objects.extend(self._traverse(test_p, root[k]))

        # elif type(root) == list:
        #     for i in root:
        #         bookmark_objects.extend(self._traverse(test_p, i))
        # return bookmark_objects

class Completed:
    def __init__(self, filename):
        self.filename = filename
        self.urls = []
        if os.path.exists(self.filename):
            with open(self.filename) as f:
                self.urls = f.read().splitlines()

    def completed_p(self, url):
        return url in self.urls

    def add(self, url):
        self.urls.append(url)

    def save(self):
        with open(self.filename, 'w') as f:
            f.write('\n'.join(self.urls))

b = Bookmarks(CHROMIUM_BOOKMARKS)
c = Completed(COMPLETED_FILE)

b.archive_youtube(lambda url: not c.completed_p(url), c.add)

c.save()
