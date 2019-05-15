module ActiveRecord
  module ConnectionAdapters
    module Redshift
      module ColumnMethods
        # Defines the primary key field.
        # Use of the native PostgreSQL UUID type is supported, and can be used
        # by defining your tables as such:
        #
        #   create_table :stuffs, id: :uuid do |t|
        #     t.string :content
        #     t.timestamps
        #   end
        #
        # By default, this will use the +uuid_generate_v4()+ function from the
        # +uuid-ossp+ extension, which MUST be enabled on your database. To enable
        # the +uuid-ossp+ extension, you can use the +enable_extension+ method in your
        # migrations. To use a UUID primary key without +uuid-ossp+ enabled, you can
        # set the +:default+ option to +nil+:
        #
        #   create_table :stuffs, id: false do |t|
        #     t.primary_key :id, :uuid, default: nil
        #     t.uuid :foo_id
        #     t.timestamps
        #   end
        #
        # You may also pass a different UUID generation function from +uuid-ossp+
        # or another library.
        #
        # Note that setting the UUID primary key default value to +nil+ will
        # require you to assure that you always provide a UUID value before saving
        # a record (as primary keys cannot be +nil+). This might be done via the
        # +SecureRandom.uuid+ method and a +before_save+ callback, for instance.
        def primary_key(name, type = :primary_key, options = {})
          return super unless type == :uuid
          options[:default] = options.fetch(:default, 'uuid_generate_v4()')
          options[:primary_key] = true
          column name, type, options
        end

        def json(name, options = {})
          column(name, :json, options)
        end

        def jsonb(name, options = {})
          column(name, :jsonb, options)
        end
      end

      class ColumnDefinition < Struct.new(:name, :type, :limit, :encode, :precision, :scale, :default, :null, :first, :after, :auto_increment, :primary_key, :collation, :sql_type, :comment) #:nodoc:

        def primary_key?
          primary_key || type.to_sym == :primary_key
        end
      end

      class TableDefinition < ActiveRecord::ConnectionAdapters::TableDefinition
        include ColumnMethods
        attr_reader :schema, :diststyle, :distkey, :sortkey, :sortstyle

        def initialize(name, temporary = false, options = nil, as = nil, comment: nil,
                       sortstyle: "COMPOUND", sortkey: nil, diststyle: "EVEN", distkey: nil, schema: "public")
          @columns_hash = {}
          @indexes = []
          @foreign_keys = []
          @primary_keys = nil
          @temporary = temporary
          @options = options
          @as = as
          @name = name
          @schema = schema.nil? ? "public" : schema
          @comment = comment
          @sortstyle = sortstyle.nil? ? "COMPOUND" : sortstyle
          @sortkey = sortkey
          @distkey = distkey
          @diststyle = diststyle.nil? ? "EVEN" : diststyle
        end

        def new_column_definition(name, type, options) # :nodoc:
          type = aliased_types(type.to_s, type)
          column = create_column_definition name, type
          column.limit       = options[:limit]
          column.precision   = options[:precision]
          column.scale       = options[:scale]
          column.default     = options[:default]
          column.null        = options[:null]
          column.first       = options[:first]
          column.after       = options[:after]
          column.auto_increment = options[:auto_increment]
          column.primary_key = type == :primary_key || options[:primary_key]
          column.collation   = options[:collation]
          column.comment     = options[:comment]
          column.encode = options[:encoding]
          column
        end

        private

        def create_column_definition(name, type)
          Redshift::ColumnDefinition.new name, type
        end
      end

      class Table < ActiveRecord::ConnectionAdapters::Table
        include ColumnMethods
      end
    end
  end
end
