package com.xxl.job.admin.controller.biz;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.xxl.job.admin.constant.Consts;
import com.xxl.job.admin.mapper.XxlJobGroupMapper;
import com.xxl.job.admin.mapper.XxlJobInfoMapper;
import com.xxl.job.admin.model.XxlJobGroup;
import com.xxl.job.admin.model.XxlJobInfo;
import com.xxl.job.admin.scheduler.config.XxlJobAdminBootstrap;
import com.xxl.job.admin.service.XxlJobService;
import com.xxl.job.core.constant.Const;
import com.xxl.sso.core.model.LoginInfo;
import com.xxl.tool.json.GsonTool;
import com.xxl.tool.response.Response;
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
    public Response<String> lip(HttpServletRequest request, @PathVariable("uri") String uri, @RequestBody(required = false) String data) {

        // valid
        if (!"POST".equalsIgnoreCase(request.getMethod())) {
            return Response.ofFail("invalid request, HttpMethod not support.");
        }
        if (uri == null || uri.isEmpty()) {
            return Response.ofFail("invalid request, uri-mapping empty.");
        }

        String accessToken = XxlJobAdminBootstrap.getInstance().getAccessToken();
        if (accessToken != null && !accessToken.isEmpty()) {
            String token = request.getHeader(Const.XXL_JOB_ACCESS_TOKEN);
            if (!accessToken.equals(token)) {
                return Response.ofFail("The access token is wrong.");
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
                    return Response.ofFail("parameter 【appname】 error");
                }
                List<XxlJobGroup> list = xxlJobGroupMapper.findList(appname.trim(), null);
                Gson gson = new Gson();
                String json = gson.toJson(list);
                return Response.ofSuccess(json);
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
                    return Response.ofFail("parameter 【id】 error");
                }
                return xxlJobService.remove(id, loginInfo);
            }

            case "stop": {
                Map<String, String> params = new Gson().fromJson(data, new TypeToken<Map<String, String>>() {
                }.getType());
                int id = parseInt(params.get("id"));
                if (id <= 0) {
                    return Response.ofFail("parameter 【id】 error");
                }
                return xxlJobService.stop(id, loginInfo);
            }

            case "start": {
                Map<String, String> params = new Gson().fromJson(data, new TypeToken<Map<String, String>>() {
                }.getType());
                int id = parseInt(params.get("id"));
                if (id <= 0) {
                    return Response.ofFail("parameter 【id】 error");
                }
                return xxlJobService.start(id, loginInfo);
            }

            case "findInfoList": {
                Map<String, String> params = new Gson().fromJson(data, new TypeToken<Map<String, String>>() {
                }.getType());
                int jobGroup = parseInt(params.get("jobGroup"));
                if (jobGroup <= 0) {
                    return Response.ofFail("parameter 【jobGroup】 error");
                }

                List<XxlJobInfo> list = xxlJobInfoMapper.findList(
                        jobGroup,
                        parseInt(params.get("triggerStatus")),
                        params.get("jobDesc"),
                        params.get("executorHandler"),
                        params.get("author"));

                Gson gson = new Gson();
                String json = gson.toJson(list);
                return Response.ofSuccess(json);
            }
            default:
                return Response.ofFail("invalid request, uri-mapping(" + uri + ") not found.");
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
