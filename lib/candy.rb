# encoding: utf-8

require 'candy/crunch'
require 'candy/exceptions'
require 'candy/wrapper'
require 'candy/collection'

require 'candy/hash'
require 'candy/array'
require 'candy/piece'


module Candy

  # Special keys for Candy metadata in the Mongo store. We try to keep these to a minimum,
  # and we're using moderately obscure Unicode symbols to reduce the odds of collisions.
  # If by some strange happenstance you might have single-character keys in your Mongo
  # collections that use the 'CIRCLED LATIN SMALL LETTER' Unicode set, you may need to
  # change these constants.  Just be consistent about it if you want to use embedded
  # documents in Candy.
  CLASS_KEY_STR = 'ⓒ'
  CLASS_KEY = CLASS_KEY_STR.to_sym
  EMBED_KEY_STR = 'ⓔ'
  EMBED_KEY = EMBED_KEY_STR.to_sym

end
