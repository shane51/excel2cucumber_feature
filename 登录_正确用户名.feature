# language: zh-CN

@基础功能
功能: 登录

    场景: 登录_正确用户名
    
        假如 我等待文本"登录"
    
        当 我在第"1"个输入框里输入"gossipgeek@thoughtworks.com"
    
        当 我在第"2"个输入框里输入"pass1234"
    
        当 我按下"登录"按钮
    
        那么 我等待文本"GossipGeek"
    
        那么 我看到"杂志"
    
        那么 我截取屏幕图片
    
