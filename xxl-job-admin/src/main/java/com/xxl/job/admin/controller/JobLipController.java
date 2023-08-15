package com.xxl.job.admin.controller;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.xxl.job.admin.controller.annotation.PermissionLimit;
import com.xxl.job.admin.core.conf.XxlJobAdminConfig;
import com.xxl.job.admin.core.model.XxlJobGroup;
import com.xxl.job.admin.core.model.XxlJobInfo;
import com.xxl.job.admin.dao.XxlJobGroupDao;
import com.xxl.job.admin.service.XxlJobService;
import com.xxl.job.core.biz.model.ReturnT;
import com.xxl.job.core.util.GsonTool;
import com.xxl.job.core.util.XxlJobRemotingUtil;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import java.util.List;
import java.util.Map;

/**
 * Created by tabtabansi on 2023年5月19日.
 */
@Controller
@RequestMapping("/lip")
public class JobLipController {
    @Resource
    public XxlJobGroupDao xxlJobGroupDao;
    @Resource
    private XxlJobService xxlJobService;


    @RequestMapping("/{uri}")
    @ResponseBody
    @PermissionLimit(limit = false)
    public ReturnT<String> lip(HttpServletRequest request, @PathVariable("uri") String uri, @RequestBody(required = false) String data) {

        // valid
        if (!"POST".equalsIgnoreCase(request.getMethod())) {
            return new ReturnT<>(ReturnT.FAIL_CODE, "invalid request, HttpMethod not support.");
        }
        if (uri == null || uri.trim().length() == 0) {
            return new ReturnT<>(ReturnT.FAIL_CODE, "invalid request, uri-mapping empty.");
        }
        if (XxlJobAdminConfig.getAdminConfig().getAccessToken() != null
                && XxlJobAdminConfig.getAdminConfig().getAccessToken().trim().length() > 0
                && !XxlJobAdminConfig.getAdminConfig().getAccessToken().equals(request.getHeader(XxlJobRemotingUtil.XXL_JOB_ACCESS_TOKEN))) {
            return new ReturnT<>(ReturnT.FAIL_CODE, "The access token is wrong.");
        }

        // services mapping
        switch (uri) {
            case "findGroupList": {
                Map<String, String> keyValueMap = new Gson().fromJson(data, new TypeToken<Map<String, String>>() {
                }.getType());
                if (keyValueMap.size() != 1) {
                    return new ReturnT<>(ReturnT.FAIL_CODE, "parameter error");
                }
                List<XxlJobGroup> list = xxlJobGroupDao.findList(
                        keyValueMap.get("appname"), null
                );
                Gson gson = new Gson();
                String json = gson.toJson(list);
                return new ReturnT<>(json);
            }

            case "update": {
                XxlJobInfo xxlJobInfo = GsonTool.fromJson(data, XxlJobInfo.class);
                return xxlJobService.update(xxlJobInfo);
            }

            case "add": {
                XxlJobInfo xxlJobInfo = GsonTool.fromJson(data, XxlJobInfo.class);
                return xxlJobService.add(xxlJobInfo);
            }

            case "remove": {
                Map<String, String> keyValueMap = new Gson().fromJson(data, new TypeToken<Map<String, String>>() {
                }.getType());
                if (keyValueMap.size() != 1) {
                    return new ReturnT<>(ReturnT.FAIL_CODE, "parameter error");
                }
                return xxlJobService.remove(Integer.parseInt(keyValueMap.get("id")));
            }

            case "stop": {
                Map<String, String> keyValueMap = new Gson().fromJson(data, new TypeToken<Map<String, String>>() {
                }.getType());
                if (keyValueMap.size() != 1) {
                    return new ReturnT<>(ReturnT.FAIL_CODE, "parameter error");
                }
                return xxlJobService.stop(Integer.parseInt(keyValueMap.get("id")));
            }

            case "start": {
                Map<String, String> keyValueMap = new Gson().fromJson(data, new TypeToken<Map<String, String>>() {
                }.getType());
                if (keyValueMap.size() != 1) {
                    return new ReturnT<>(ReturnT.FAIL_CODE, "parameter error");
                }
                return xxlJobService.start(Integer.parseInt(keyValueMap.get("id")));
            }

            case "findInfoList": {
                Map<String, String> keyValueMap = new Gson().fromJson(data, new TypeToken<Map<String, String>>() {
                }.getType());
                if (keyValueMap.size() != 5) {
                    return new ReturnT<>(ReturnT.FAIL_CODE, "parameter error");
                }
                String list = xxlJobService.findList(
                        Integer.parseInt(keyValueMap.get("jobGroup")),
                        Integer.parseInt(keyValueMap.get("triggerStatus")),
                        keyValueMap.get("jobDesc"),
                        keyValueMap.get("executorHandler"),
                        keyValueMap.get("author"));
                return new ReturnT<>(list);
            }
            default:
                return new ReturnT<>(ReturnT.FAIL_CODE, "invalid request, uri-mapping(" + uri + ") not found.");
        }
    }

}
