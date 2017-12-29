#!/usr/bin/env python3


from argparse import ArgumentParser
from subprocess import run
from sys import argv, stderr
from time import time


def main():
  arg_parser = ArgumentParser(description='Display a macOS User notification.')
  arg_parser.add_argument('-title', default='Notification')
  arg_parser.add_argument('-subtitle', default=None)
  arg_parser.add_argument('-message', default=None)
  arg_parser.add_argument('-after', type=int, default=None)
  arg_parser.add_argument('-image', default=None)

  arg_parser.add_argument('command', nargs='*', default=[])
  # TODO: timeout.

  args = arg_parser.parse_args()

  title = args.title
  subtitle = args.subtitle
  message = args.message
  cmd = args.command

  try:
    img_name_constant = img_cocoa_name(image_names[args.image]) if args.image else None
  except KeyError:
    print('valid image names:', file=stderr)
    for n in sorted(image_names):
      print('  ', n, sep='', file=stderr)
    exit(f'invalid image name: {args.image!r}')

  if cmd:
    if not subtitle: subtitle = ' '.join(cmd)
    start_time = time()
    res = run(cmd)
    run_time = time() - start_time
    code = res.returncode
    if args.after is not None and run_time <= args.after: exit(code)
    if code != 0:
      if not message: message = 'FAILED'
  else:
    code = 0

  # import objc lazily because it is very slow to load.
  import AppKit
  from Foundation import NSDate, NSUserNotification, NSUserNotificationCenter
  from AppKit import NSImage

  note = NSUserNotification.alloc().init()

  note.setTitle_(title)
  if subtitle: note.setSubtitle_(subtitle)
  if message: note.setInformativeText_(message)
  if img_name_constant:
    img_name = getattr(AppKit, img_name_constant)
    img = NSImage.imageNamed_(img_name)
    assert img, img_name
    note.setContentImage_(img)
  note.setHasActionButton_(False)
  note.setDeliveryDate_(NSDate.date())
  NSUserNotificationCenter.defaultUserNotificationCenter().scheduleNotification_(note)
  exit(code)


def proper_case(s): return s[0].upper() + s[1:]

def img_cocoa_name(swift_name): return 'NSImageName' + proper_case(swift_name)

# from https://developer.apple.com/documentation/appkit/nsimage/1520015-imagenamed

image_names = { n.replace('Template', '') : n for n in [
  'actionTemplate',
  'addTemplate',
  'advanced',
  'applicationIcon',
  'bluetoothTemplate',
  'bonjour',
  'bookmarksTemplate',
  'caution',
  'colorPanel',
  'columnViewTemplate',
  'computer',
  'enterFullScreenTemplate',
  'everyone',
  'exitFullScreenTemplate',
  'flowViewTemplate',
  'folder',
  'folderBurnable',
  'folderSmart',
  'followLinkFreestandingTemplate',
  'fontPanel',
  'goLeftTemplate',
  'goRightTemplate',
  'homeTemplate',
  'iChatTheaterTemplate',
  'iconViewTemplate',
  'info',
  'invalidDataFreestandingTemplate',
  'listViewTemplate',
  'lockLockedTemplate',
  'lockUnlockedTemplate',
  'menuMixedStateTemplate',
  'menuOnStateTemplate',
  'multipleDocuments',
  'network',
  'pathTemplate',
  'preferencesGeneral',
  'quickLookTemplate',
  'refreshFreestandingTemplate',
  'refreshTemplate',
  'removeTemplate',
  'revealFreestandingTemplate',
  'rightFacingTriangleTemplate',
  'shareTemplate',
  'slideshowTemplate',
  'smartBadgeTemplate',
  'statusAvailable',
  'statusNone',
  'statusPartiallyAvailable',
  'statusUnavailable',
  'stopProgressFreestandingTemplate',
  'stopProgressTemplate',
  'trashEmpty',
  'trashFull',
  'user',
  'userAccounts',
  'userGroup',
  'userGuest',
]}

image_names.update({
  'arrow-left'  : 'goLeftTemplate',
  'arrow-right' : 'goRightTemplate',
  'document'    : 'multipleDocuments',
  'eye'         : 'quickLookTemplate',
  'group'       : 'userGroup',
  'lock'        : 'lockLockedTemplate',
  'play'        : 'slideshowTemplate',
  'theater'     : 'iChatTheaterTemplate',
  'unlock'      : 'lockUnlockedTemplate',
})

if __name__ == '__main__': main()
