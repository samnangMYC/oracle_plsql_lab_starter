package com.example.fcubs.stdcifd.ejb;

import com.example.fcubs.stdcifd.model.GatewayResult;
import javax.ejb.Local;

@Local
public interface CustomerCifServiceLocal {
    GatewayResult process(String operation, String requestXml, String authenticatedUserId, String branchCode);
}
