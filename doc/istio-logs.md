# logs

## envoy log

<https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log>
<https://en.cppreference.com/w/cpp/io/manip/put_time>

```txt
"[sidecar-proxy-access] [%START_TIME%] \"%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%\" %RESPONSE_CODE% %RESPONSE_FLAGS% \"%DYNAMIC_METADATA(istio.mixer:status)%\" \"%UPSTREAM_TRANSPORT_FAILURE_REASON%\" %BYTES_RECEIVED% %BYTES_SENT% %DURATION% %RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)% \"%REQ(X-FORWARDED-FOR)%\" \"%REQ(USER-AGENT)%\" \"%REQ(X-REQUEST-ID)%\" \"%REQ(:AUTHORITY)%\" \"%UPSTREAM_HOST%\" %UPSTREAM_CLUSTER% %UPSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_REMOTE_ADDRESS% %REQUESTED_SERVER_NAME%\n"

%Y-%m-%dT%H:%M:%S%z %s
%Y-%m-%dT%H:%M:%S.%fZ
2019-09-02T15:52:06.727Z

%{yyyy-MM-dd'T'HH:mm:ss.SSSZZZZ}t
```

## 公司格式

```shell
%{yyyy-MM-dd'T'HH:mm:ss.SSSZZZZ}t %S %a %{X-Forwarded-For}i %{_CURRENT_USER_}s %m %s %b %D "%I" "%U" "%q" "%{Referer}i" "%{User-Agent}i" "%{X-Request-ID}i"
```

- 整合

```shell
%{yyyy-MM-dd'T'HH:mm:ss.SSSZZZZ}t  时间戳                       %START_TIME%
%S                                 UserSessionId               %DOWNSTREAM_TLS_SESSION_ID%
%a                                 RemoteIP                    %DOWNSTREAM_REMOTE_ADDRESS%
%{X-Forwarded-For}i                                            %REQ(X-FORWARDED-FOR)%
%{_CURRENT_USER_}s                                             %REQ(_CURRENT_USER_)%
%m                                                             %REQ(:METHOD)%
%s                                                             %RESPONSE_CODE%
%b                                 请求返回字节长度               %BYTES_SENT%
%D                                 请求处理耗时，毫秒             %DURATION%
"%I"                               当前请求线程名                ""
"%U"                               请求URL Path                "%REQ(X-ENVOY-ORIGINAL-PATH?:PATH)%"
"%q"                               查询字符串                   ""
"%{Referer}i"                                                  "%REQ(REFERER)%"
"%{User-Agent}i"                                               "%REQ(USER-AGENT)%"
"%{X-Request-ID}i"                                             "%REQ(X-REQUEST-ID)%"

```
