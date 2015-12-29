require 'candy/crunch'
require 'candy/hash'

module Candy

  # Handles Mongo queries for cursors upon a particular Mongo collection.
  module Collection
    FIND_OPTIONS = [:projection, :distinct, :skip, :limit, :sort, :hint, :snapshot, :count]
    UP_SORTS     = [Mongo::Index::ASCENDING, 'ascending', 'asc', :ascending, :asc, 1, :up]
    DOWN_SORTS   = [Mongo::Index::DESCENDING, 'descending', 'desc', :descending, :desc, -1, :down]

    include Enumerable

    module ClassMethods
      include Crunch::ClassMethods

      attr_reader :_candy_piece

      # Sets the collection that all queries run against.  You can also
      # specify a class that includes Candy::Piece that will be instantiated
      # for all found records. Otherwise the collection name is used as a
      # default, and CandyHash is a fallback.
      def collects(collection, piece = nil)
        collectible     = camelcase(collection.to_s.split("::").last)
        piecemeal       = namespace + (piece ? camelcase(piece) : collectible)
        self.collection = collectible
        @_candy_piece   = Kernel.qualified_const_get(piecemeal) || CandyHash
      end

      def all(options={})
        self.new(options)
      end

      def count(options={})
        collection.find(options).count
      end

      def method_missing(name, *args, &block)
        coll = self.new
        coll.send(name, *args, &block)
      end
    private
      # Retrieves the 'BlahModule::BleeModule::' part of the class name, so that we
      # can put other things in the same namespace.
      def namespace
        name[/^.*::/] || '' # Hooray for greedy matching
      end

      # Modified from ActiveSupport (http://rubyonrails.org)
      def camelcase(stringy)
        stringy.to_s.gsub(/(?:^|_)(.)/) {$1.upcase}
      end

      # Creates a method in the same namespace as the included class that points to
      # 'all', for easier semantics.
      def self.extended(receiver)
        Factory.magic_method(receiver, 'all', 'conditions={}')
      end

    end  # Here endeth the ClassMethods module

    def initialize(*args, &block)
      conditions = args.pop || {}
      super
      @_candy_query = {}
      if conditions.is_a?(Hash)
        @_candy_options = extract_options(conditions)
        @_candy_query.merge!(conditions)
      else
        @_candy_options = {}
      end
      refresh_cursor
    end

    def method_missing(name, *args, &block)
      if @_candy_cursor.respond_to?(name)
        @_candy_cursor = @_candy_cursor.send(name, *args, &block)
        self
      elsif FIND_OPTIONS.include?(name)
        @_candy_options[name] = args.shift
        refresh_cursor
        self
      else
        @_candy_query[name] = args.shift
        @_candy_query.merge!(args) if args.is_a?(Hash)
        refresh_cursor
        self
      end
    end


    # Makes our collection enumerable.  This relies heavily on Mongo::Cursor methods --
    # we only reimplement it so that the objects we return can be Candy objects.
    def each
      refresh_cursor
      @_candy_cursor.each do |this|
        yield self.class._candy_piece.new(this)
      end
    end

    # Get our next document as a Candy object, if there is one.
    # def next
    #   if this = @_candy_cursor.next_document
    #     self.class._candy_piece.new(this)
    #   end
    # end

    # Determines the sort order for this collection, with somewhat simpler semantics than
    # the MongoDB options.  Each value is either a field name (which defaults to ascending sort)
    # or a direction (which modifies the field name immediately prior) or a two-element array of
    # same.  Direction can be :up or :down in addition to Mongo's accepted values of :ascending,
    # 'asc', 1, etc.
    #
    # As an added bonus, sorts can also be chained.  If you call #sort more than once then all
    # sorts will be applied in the order in which you called them.
    def sort(*fields)
      fields = fields.flatten(1)
      @_candy_sort ||= {}
      return self if fields.empty?
      return self if Hash === fields.first and fields.first.empty?

      temp_sort =
        if Hash === fields
          fields
        elsif Array === fields.first
          fields.to_h
        elsif Hash === fields.first
          fields.first
        else
          fields << :asc if fields.size == 1
          [fields].to_h
        end

      temp_sort.each do |k,v|
        if UP_SORTS.include?(v)
          temp_sort[k] = Mongo::Index::ASCENDING
        elsif DOWN_SORTS.include?(v)
          temp_sort[k] = Mongo::Index::DESCENDING
        else
          temp_sort[k] = Mongo::Index::ASCENDING
        end
      end

      @_candy_sort.merge!(temp_sort)
      @_candy_cursor.sort(@_candy_sort)

      self
    end


  private

    def refresh_cursor
      @_candy_sort ||= {}
      @_candy_cursor = self.class.collection.find(@_candy_query.dup).sort(@_candy_sort.dup)
    end

    def extract_options(hash)
      options = {}
      (FIND_OPTIONS & hash.keys).each do |key|
        options[key] = hash.delete(key)
      end
      options
    end

    def self.included(receiver)
      receiver.extend  ClassMethods
    end
  end
end
