package com.xxl.job.admin.controller.biz;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.xxl.job.admin.constant.Consts;
import com.xxl.job.admin.mapper.XxlJobGroupMapper;
import com.xxl.job.admin.mapper.XxlJobInfoMapper;
import com.xxl.job.admin.model.XxlJobGroup;
import com.xxl.job.admin.model.XxlJobInfo;
import com.xxl.job.admin.scheduler.conf.XxlJobAdminConfig;
import com.xxl.job.admin.service.XxlJobService;
import com.xxl.job.core.biz.model.ReturnT;
import com.xxl.job.core.util.GsonTool;
import com.xxl.job.core.util.XxlJobRemotingUtil;
import com.xxl.sso.core.model.LoginInfo;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletRequest;

import java.util.Collections;
import java.util.List;
import java.util.Map;

/**
 * Created by lip team on 2023-05-19.
 */
@Controller
@RequestMapping("/lip")
public class JobLipController {
    @Resource
    private XxlJobGroupMapper xxlJobGroupMapper;
    @Resource
    private XxlJobInfoMapper xxlJobInfoMapper;
    @Resource
    private XxlJobService xxlJobService;

    @RequestMapping("/{uri}")
    @ResponseBody
    public ReturnT<String> lip(HttpServletRequest request, @PathVariable("uri") String uri, @RequestBody(required = false) String data) {

        // valid
        if (!"POST".equalsIgnoreCase(request.getMethod())) {
            return new ReturnT<>(ReturnT.FAIL_CODE, "invalid request, HttpMethod not support.");
        }
        if (uri == null || uri.isEmpty()) {
            return new ReturnT<>(ReturnT.FAIL_CODE, "invalid request, uri-mapping empty.");
        }
        XxlJobAdminConfig adminConfig = XxlJobAdminConfig.getAdminConfig();
        if (adminConfig.getAccessToken() != null && !adminConfig.getAccessToken().isEmpty()) {
            String token = request.getHeader(XxlJobRemotingUtil.XXL_JOB_ACCESS_TOKEN);
            if (!adminConfig.getAccessToken().equals(token)) {
                return new ReturnT<>(ReturnT.FAIL_CODE, "The access token is wrong.");
            }
        }

        // login info
        LoginInfo loginInfo = new LoginInfo();
        loginInfo.setRoleList(Collections.singletonList(Consts.ADMIN_ROLE));

        // services mapping
        switch (uri) {
            case "findGroupList": {
                Map<String, String> params = new Gson().fromJson(data, new TypeToken<Map<String, String>>() {
                }.getType());
                String appname = params.get("appname");
                if (appname == null || appname.trim().isEmpty()) {
                    return new ReturnT<>(ReturnT.FAIL_CODE, "parameter 【appname】 error");
                }
                List<XxlJobGroup> list = xxlJobGroupMapper.findList(appname.trim(), null);
                Gson gson = new Gson();
                String json = gson.toJson(list);
                return ReturnT.ofSuccess(json);
            }

            case "update": {
                XxlJobInfo xxlJobInfo = GsonTool.fromJson(data, XxlJobInfo.class);
                return xxlJobService.update(xxlJobInfo, loginInfo);
            }

            case "add": {
                XxlJobInfo xxlJobInfo = GsonTool.fromJson(data, XxlJobInfo.class);
                return xxlJobService.add(xxlJobInfo, loginInfo);
            }

            case "remove": {
                Map<String, String> params = new Gson().fromJson(data, new TypeToken<Map<String, String>>() {
                }.getType());
                int id = parseInt(params.get("id"));
                if (id <= 0) {
                    return ReturnT.ofFail("parameter 【id】 error");
                }
                return xxlJobService.remove(id, loginInfo);
            }

            case "stop": {
                Map<String, String> params = new Gson().fromJson(data, new TypeToken<Map<String, String>>() {
                }.getType());
                int id = parseInt(params.get("id"));
                if (id <= 0) {
                    return ReturnT.ofFail("parameter 【id】 error");
                }
                return xxlJobService.stop(id, loginInfo);
            }

            case "start": {
                Map<String, String> params = new Gson().fromJson(data, new TypeToken<Map<String, String>>() {
                }.getType());
                int id = parseInt(params.get("id"));
                if (id <= 0) {
                    return new ReturnT<>(ReturnT.FAIL_CODE, "parameter 【id】 error");
                }
                return xxlJobService.start(id, loginInfo);
            }

            case "findInfoList": {
                Map<String, String> params = new Gson().fromJson(data, new TypeToken<Map<String, String>>() {
                }.getType());
                int jobGroup = parseInt(params.get("jobGroup"));
                if (jobGroup <= 0) {
                    return new ReturnT<>(ReturnT.FAIL_CODE, "parameter 【jobGroup】 error");
                }

                List<XxlJobInfo> list = xxlJobInfoMapper.findList(
                        jobGroup,
                        parseInt(params.get("triggerStatus")),
                        params.get("jobDesc"),
                        params.get("executorHandler"),
                        params.get("author"));

                Gson gson = new Gson();
                String json = gson.toJson(list);
                return ReturnT.ofSuccess(json);
            }
            default:
                return new ReturnT<>(ReturnT.FAIL_CODE, "invalid request, uri-mapping(" + uri + ") not found.");
        }
    }

    private int parseInt(String str) {
        try {
            return Integer.parseInt(str);
        } catch (NumberFormatException e) {
            return 0;
        }
    }

}
