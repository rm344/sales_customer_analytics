{% macro create_external_json_table(table_name, folder_name) %}
    {% set create_query %}
        CREATE OR REPLACE EXTERNAL TABLE ct_rajat_mahore_db.azure_raw_data.{{ table_name }}
        WITH LOCATION = @ct_rajat_mahore_db.azure_raw_data.azure_raw_stage/Capstone_Project_Data/{{ folder_name }}/
        FILE_FORMAT = (FORMAT_NAME = 'ct_rajat_mahore_db.azure_raw_data.json_file_format')
    {% endset %}
 
    {% do run_query(create_query) %}
    {% do log("External table " ~ table_name ~ " created successfully in schema!", info=True) %}
{% endmacro %}