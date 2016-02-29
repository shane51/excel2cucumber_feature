require 'rspec'
require './import_excel'

current_project_id = 'Test_project'
test_project_root = 'tmp'

describe Importer do


  it "Import info from excel file" do
    importer = Importer.new("REA_Phase1.xls",current_project_id)

    name = importer.app_name
    case_info = importer.title_row

    expect(name).to eq(current_project_id)
    expect(case_info).to eq %w{ 故事 业务功能 业务场景 预置条件 测试步骤 预期结果 测试结果 测试方式 用例等级 }
  end

  it "when build project folders, if excel title row format not match will show error" do
    importer = Importer.new("REA_Phase1.xls",current_project_id)
    required_title = %w{ 功能 业务场景 预置条件 测试步骤 预期结果 测试结果 测试方式 用例等级 }
    expect{ importer.validate_excel_format(required_title) }.to raise_error('导入格式不匹配')
  end

  it "when build project folders, if excel title row format match will show match" do
    importer = Importer.new("REA_Phase1.xls",current_project_id)
    required_title = %w{ 故事 业务功能 业务场景 预置条件 测试步骤 预期结果 测试结果 测试方式 用例等级 }
    alert = importer.validate_excel_format(required_title)
    expect(alert).to eq('格式匹配成功')
  end

  it "when parse 1 case row, I should see hash about case path and case name" do
    importer = Importer.new("REA_Phase1.xls",current_project_id)
    testcase1 = %w{ 登录 login 普通用户登陆 我等待登录页面 我输入用户名并登录 登录成功}
    testcase2 = %w{ 登录 login/login 普通用户登陆 我等待登录页面 我输入用户名并登录 登录成功}

    case_path_hash_one_level_feature = importer.case_path_mapper({},testcase1)
    case_path_hash_two_level_feature = importer.case_path_mapper({},testcase2)
    expect(case_path_hash_one_level_feature).to eq(Hash["#{current_project_id}" + '/features/login','普通用户登陆'])
    expect(case_path_hash_two_level_feature).to eq(Hash["#{current_project_id}" + '/features/login/login','普通用户登陆'])
  end

  it "when parse 2 case row, I should  get hash about case path and case name" do
    importer = Importer.new("REA_Phase1.xls",current_project_id)
    testcase1 = %w{ 登录 login 普通用户登陆 我等待登录页面 我输入用户名并登录 登录成功}
    testcase2 = %w{ 登录 logout VIP用户登陆 我等待登录页面 我输入用户名并登录 登录成功}
    case_path_map_test = {"#{current_project_id}/features/logout"=>"普通用户登陆"}
    case_path_hash_same_scenario = importer.case_path_mapper(case_path_map_test,testcase1)
    case_path_hash_same_feature = importer.case_path_mapper(case_path_map_test,testcase2)
    expect(case_path_hash_same_scenario).to eq(Hash["#{current_project_id}/features/logout","普通用户登陆","#{current_project_id}/features/login",'普通用户登陆'])
    expect(case_path_hash_same_feature).to eq(Hash["#{current_project_id}/features/logout",["普通用户登陆", "VIP用户登陆"]])
  end


  it "case steps in one call should be a array" do
    importer = Importer.new("REA_Phase1.xls",current_project_id)
    cases = importer.testcases
    case_steps = cases[0][4]
    case_steps_array = importer.step_formater(case_steps)
    # expected_steps_array = ['当 我在第"1"个输入框里输入"gossipgeek@thoughtworks.com"', '当 我在第"2"个输入框里输入"pass1234"', '当 我按下"登录"按钮']
    expected_steps_array = ["当 我在第\"1\"个输入框里输入\"gossipgeek@thoughtworks.com\"\n", "当 我在第\"2\"个输入框里输入\"pass1234\"\n", "当 我按下\"登录\"按钮\n"]
    expect(case_steps_array).to eq(expected_steps_array)
  end

  it "can build feature file" do
    importer = Importer.new("REA_Phase1.xls",current_project_id)
    cases = importer.testcases
    importer.case_builder(cases[0],'.')
    feaure_file = File.readlines('登录_正确用户名.feature')
    expected_feature =File.readlines('登录_正确用户名_test.feature')
    expect(feaure_file).to eq(expected_feature)
  end

  it "when build single case folders, I should see folders and file build successfully" do
    importer = Importer.new("REA_Phase1.xls",current_project_id)
    cases = importer.testcases
    case_path_map_first_case = importer.case_path_mapper({},cases[0])
    importer.build_feature_file_and_folder(case_path_map_first_case,test_project_root,cases[0])
    case_path = case_path_map_first_case.keys.first.to_s
    case_name = case_path_map_first_case.values.first.to_s + '.feature'

    expected_case_name_full_path = File.join(test_project_root,case_path,case_name)
    expect(File.file?(expected_case_name_full_path)).to eq(true)
    FileUtils.rm_rf ["#{test_project_root}/#{current_project_id}"]
  end

  it "when build Multipule case folders, I should see folders and files build successfully" do

    importer = Importer.new("REA_Phase1.xls",current_project_id)
    required_title = %w{ 故事 业务功能 业务场景 预置条件 测试步骤 预期结果 测试结果 测试方式 用例等级 }
    importer.build_project_folders(required_title,test_project_root)

    cases = importer.testcases
    cases.each do |testcase|
      case_path_map_single_case = importer.case_path_mapper({},testcase)
      case_path = case_path_map_single_case.keys.first.to_s
      case_name = case_path_map_single_case.values.first.to_s + '.feature'
      expected_case_name_full_path = File.join(test_project_root,case_path,case_name)
      expect(File.file?(expected_case_name_full_path)).to eq(true)
    end
    FileUtils.rm_rf ["#{test_project_root}/#{current_project_id}"]
  end


end
