require 'spreadsheet'
require 'fileutils'

  class Importer
    attr_reader :app_name, :title_row, :testcases
    def initialize(excel_file,current_app_name)
      @app_name = current_app_name
      rows = import_excel(excel_file)
      @title_row = rows.slice!(0)
      @testcases = rows
    end

    def import_excel(excel_file)
      worksheet = Spreadsheet.open(excel_file).worksheet(0)
      rows = []
      worksheet.each do |row|
        rows << row
      end
      rows
    end

    def build_project_folders(required_title,import_excel_root_path)
      validate_excel_format(required_title)
      @testcases.each do |testcase|
         case_path_map = case_path_mapper({},testcase)
         build_feature_file_and_folder(case_path_map,import_excel_root_path,testcase)
      end
    end

    def validate_excel_format(required_format)
      @title_row == required_format ? '格式匹配成功' : raise('导入格式不匹配')
    end
    def build_feature_file_and_folder(case_path_map,import_excel_root_path,testcase)
      case_path = case_path_map.keys.first.to_s
      case_name = case_path_map.values.first.to_s

      feature_full_path_name = File.join(import_excel_root_path,case_path)
      FileUtils::mkdir_p(feature_full_path_name) unless File.directory?(case_path)
      case_builder(testcase,feature_full_path_name)

    end



    def case_path_mapper(case_path_hash={},testcase)

        case_feature = testcase[1]
        case_scenario = testcase[2]

        case_path = File.join(@app_name,'features',case_feature)
        if case_path_hash.has_key?(case_path)
          case_path_hash[case_path] = [case_path_hash[case_path], case_scenario]
          case_path_map = case_path_hash
        else
          case_path_map = case_path_hash.merge(Hash[case_path,case_scenario])
        end
    end

    def case_builder(testcase,file_path)
      case_story = testcase[0]
      case_feature = testcase[1]
      case_scenario = testcase[2]
      case_assumption = testcase[3]
      case_steps = testcase[4]
      case_validation = testcase[5]

      feature_file = ''
      feature_file_name = "#{case_scenario}" + ".feature"
      feature_file_path = File.join(file_path,feature_file_name)

      feature_file <<"# language: zh-CN\n"
      feature_file <<"\n@" + "#{case_story}\n"
      feature_file <<"功能: " + "#{case_feature}\n"
      feature_file <<"\n    场景: " + "#{case_scenario}\n"
      feature_file <<"\n        " + step_formater(case_assumption).join("\n        ")
      feature_file <<"\n        " + step_formater(case_steps).join("\n        ")
      feature_file <<"\n        " + step_formater(case_validation).join("\n        ")

      File.open(feature_file_path, 'w'){ |f| f.puts feature_file }
    end

    def step_formater(case_steps)
      new_case_steps = []
      case_steps.each_line do |step|
        step.gsub!(/^\d\.\s/, '')
        step.gsub!(/\，/, '')
        step.gsub!(/\n/, '')
        new_case_steps << step + "\n"
      end
      new_case_steps
    end
  end
