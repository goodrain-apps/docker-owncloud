# docker-owncloud
docker build owncloud


# 参数
    RESET：是否重新初始化应用，默认为0，非0则格式化所有数据
    
    OWN_CLOUD_PORT：应用对外端口号，默认为5000
    
    DISABLED_ORIGIN：是否删除默认管理账户.admin:owncloud
    
    OWN_CLOUD_ADMIN：自定义管理员
    
    OWN_CLOUD_PASSWORD：自定义管理员密码
    
    TRUSTED_DOMAINS: 信任的url路径

# 备注
    
    当前版本数据存储类型为sqlite。
    mysql、postsql开发中，兼容好雨平台
    
    
