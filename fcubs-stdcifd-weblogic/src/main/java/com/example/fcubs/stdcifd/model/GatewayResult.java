package com.example.fcubs.stdcifd.model;

import java.io.Serializable;

public class GatewayResult implements Serializable {
    private static final long serialVersionUID = 1L;
    private final boolean success;
    private final String responseBody;
    private final String errorCode;
    private final String errorMessage;

    public GatewayResult(boolean success, String responseBody, String errorCode, String errorMessage) {
        this.success = success;
        this.responseBody = responseBody;
        this.errorCode = errorCode;
        this.errorMessage = errorMessage;
    }

    public boolean isSuccess() { return success; }
    public String getResponseBody() { return responseBody; }
    public String getErrorCode() { return errorCode; }
    public String getErrorMessage() { return errorMessage; }
}
