头部加"*" 为必传参数，其它为可选

1>激活接口
http://m2.demo.com/api/activate/?school_name=测试机构&contract_num=10000&mac=00:01:6C:06:A6:29&token=57f20f883e
* school_name: 机构名称
* contract_num: 合同编号
* mac: 设备mac
设备首先得激活才能使用


2>登录接口 *
http://m2.demo.com/api/login/?school_id=10000&mac=00:01:6C:06:A6:29&token=57f20f883e&username=15923565897&password=123456
http://api.innoplay.cn/api/login/?school_id=10000&mac=00:01:6C:06:A6:29&token=57f20f883e&username=15926589659&password=123456

http://api.innoplay.cn/api/login/?school_id=10001&mac=00:01:6C:06:A6:29&token=57f20f883e&username=13512345678&password=123456

* school_id: 机构id
* mac: 设备mac
* username: 用户名
* password: 口令
* token:
设备登录后连接代理服，代理服进程身份验证

******
备注：
 返回 phone

3>修改密码
http://m2.demo.com/api/modifyPasswd/?school_id=10000&mac=00:01:6C:06:A6:29&token=57f20f883e&username=15923565897&oldpassword=123456&newpassword=123456
* school_id: 机构id
* mac: 设备mac
* username: 用户名
* oldpassword: 旧口令
* newpassword : 新口令
* token:


4> 学生列表 *
http://m2.demo.com/api/studentList/?school_id=10000&mac=00:01:6C:06:A6:29&token=57f20f883e&course_type=1&gender=male&classid=5
http://api.innoplay.cn/api/studentList/?school_id=10000&mac=00:01:6C:06:A6:29&token=57f20f883e&course_type=1&gender=male&classid=5
* school_id: 机构id
* mac: 设备mac
* token: 57f20f883e
course_type: 课程类型: [{1: 基础课}, {2: 特色课}, {3: 兴趣班}, {4: 考级班}]
gender: 性别 : [{male: 男}, {female: 女}]
classid: 班级id

备注：学生可以通过返回的 phone 作为账号 username 无密码登录系统， 如：
http://api.innoplay.cn/api/login/?school_id=10000&mac=00:01:6C:06:A6:29&token=57f20f883e&username=13812341234&password=

添加是否在线参数 online， 当且仅当 online 值为1时查询在线的学生
http://api.innoplay.cn/api/studentList/?school_id=10000&mac=00:01:6C:06:A6:29&token=57f20f883e&course_type=1&gender=male&classid=5&online=1

5> 课程详情
http://m2.demo.com/api/curriculumInfo/?school_id=10000&mac=00:01:6C:06:A6:29&token=57f20f883e&curriculum_id=1
http://api.innoplay.cn/api/curriculumInfo/?school_id=10000&mac=00:01:6C:06:A6:29&token=57f20f883e&curriculum_id=1

http://api.innoplay.cn/api/curriculumInfo/?school_id=10001&mac=44:2c:05:96:ff:dc&token=57f20f883e&curriculum_id=12

* school_id: 机构id
* mac: 设备mac
* token:
* curriculum_id: 课程 id

6> 课程列表
http://m2.demo.com/api/curriculumList/?school_id=10000&mac=00:01:6C:06:A6:29&token=57f20f883e
http://api.innoplay.cn/api/curriculumList/?school_id=10000&mac=00:01:6C:06:A6:29&token=57f20f883e
* school_id: 机构id
* mac: 设备mac
* token:



7> 账号基本信息 *
http://m2.demo.com/api/accountInfo/?school_id=10000&mac=00:01:6C:06:A6:29&token=57f20f883e&uid=23&phone=15923565897
* school_id: 机构id
* mac: 设备mac
* token: 57f20f883e


8> 班级列表 *
 http://m2.demo.com/api/calssList/?school_id=10000&mac=00:01:6C:06:A6:29&token=57f20f883e
 * school_id: 机构id
 * mac: 设备mac
 * token: 57f20f883e