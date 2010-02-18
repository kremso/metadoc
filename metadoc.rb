require 'rubygems'
require 'sequel'
require 'serenity'

class MetaDoc
  include Serenity::Generator

  DB = Sequel.connect('oracle:xe/hr', :user => 'hr', :password => 'hr')

  Column = Struct.new(:name, :type, :nullable, :default, :comment)
  Table = Struct.new(:name, :comment, :columns)

  TABLE_METADATA_SQL = <<-EOF
    SELECT table_name, comments
      FROM user_tab_comments
     WHERE table_type = 'TABLE'
  ORDER BY table_name
  EOF

  COLUMN_METADATA_SQL = <<-EOF
    SELECT c.column_name, c.data_type, c.data_length, c.data_precision, 
           c.nullable, c.data_default, cc.comments 
      FROM user_tab_columns c, user_col_comments cc 
     WHERE c.column_name = cc.column_name 
       AND c.table_name = cc.table_name 
       AND c.table_name = ?
  EOF

  def load_tables_metadata
    @tables = []
    DB.fetch(TABLE_METADATA_SQL) do |t|
      columns = []
      DB.fetch(COLUMN_METADATA_SQL, t[:table_name]) do |c|
        columns << Column.new(c[:column_name], c[:data_type], c[:nullable], c[:data_default], c[:comments])
      end

      @tables << Table.new(t[:table_name], t[:comments], columns)
    end

    render_odt 'table_meta.odt'
  end

end

metadoc = MetaDoc.new
metadoc.load_tables_metadata
