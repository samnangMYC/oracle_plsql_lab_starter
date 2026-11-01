package com.example.fcubs.stdcifd.ejb;

import com.example.fcubs.stdcifd.model.GatewayResult;

import javax.annotation.Resource;
import javax.ejb.SessionContext;
import javax.ejb.Stateless;
import javax.ejb.TransactionAttribute;
import javax.ejb.TransactionAttributeType;
import javax.sql.DataSource;
import java.io.Reader;
import java.io.StringReader;
import java.io.StringWriter;
import java.sql.CallableStatement;
import java.sql.Clob;
import java.sql.Connection;
import java.sql.Types;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Transactional service layer for the clone. It invokes the clone-owned
 * STPKS_STDCIFD_WS adapter, which delegates to STPKS_STDCIFD_MAIN.
 */
@Stateless(name = "CustomerCifServiceBean")
@TransactionAttribute(TransactionAttributeType.REQUIRED)
public class CustomerCifServiceBean implements CustomerCifServiceLocal {
    private static final Logger LOG = Logger.getLogger(CustomerCifServiceBean.class.getName());

    @Resource(lookup = "jdbc/FCUBSDS")
    private DataSource dataSource;

    @Resource
    private SessionContext sessionContext;

    @Override
    public GatewayResult process(String operation, String requestXml, String authenticatedUserId, String branchCode) {
        if (dataSource == null) {
            throw new IllegalStateException("WebLogic DataSource jdbc/FCUBSDS is not configured.");
        }
        try (Connection connection = dataSource.getConnection();
             CallableStatement statement = connection.prepareCall(
                 "{ call STPKS_STDCIFD_WS.PROCESS_REQUEST(?, ?, ?, ?, ?, ?, ?, ?) }")) {

            statement.setString(1, operation);
            Reader input = new StringReader(requestXml);
            statement.setCharacterStream(2, input, requestXml.length());
            statement.setString(3, authenticatedUserId);
            statement.setString(4, branchCode);
            statement.registerOutParameter(5, Types.CLOB);
            statement.registerOutParameter(6, Types.VARCHAR);
            statement.registerOutParameter(7, Types.VARCHAR);
            statement.registerOutParameter(8, Types.VARCHAR);
            statement.execute();

            String resultFlag = statement.getString(6);
            String errorCode = statement.getString(7);
            String errorMessage = statement.getString(8);
            String responseBody = readClob(statement.getClob(5));
            boolean success = "S".equalsIgnoreCase(resultFlag);

            if (!success) {
                // CMT transaction is rolled back after the EJB method returns.
                sessionContext.setRollbackOnly();
                return new GatewayResult(false, null, errorCode, errorMessage);
            }
            return new GatewayResult(true, responseBody, null, null);
        } catch (Exception e) {
            sessionContext.setRollbackOnly();
            LOG.log(Level.SEVERE, "STDCIFD database service failed for operation " + operation, e);
            throw new IllegalStateException("Customer database operation failed. Check server logs.", e);
        }
    }

    private String readClob(Clob clob) throws Exception {
        if (clob == null) return "";
        StringWriter writer = new StringWriter();
        try (Reader reader = clob.getCharacterStream()) {
            char[] buffer = new char[4096];
            int count;
            while ((count = reader.read(buffer)) >= 0) {
                writer.write(buffer, 0, count);
            }
        } finally {
            try { clob.free(); } catch (Exception ignored) { }
        }
        return writer.toString();
    }
}
