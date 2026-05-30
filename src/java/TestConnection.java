import java.sql.Connection;
import java.sql.DriverManager;

public class TestConnection {

    public static void main(String[] args) {

        String url =
        "jdbc:mysql://mysql-199a95cf-makhabaneramakoro05-32b7.e.aivencloud.com:14088/defaultdb?sslMode=REQUIRED";

        String user = "avnadmin";

        String password = "AVNS_7xlCqXw9i-vUzcLPdj9";

        try {

            Connection conn =
            DriverManager.getConnection(url, user, password);

            System.out.println("CONNECTED SUCCESSFULLY");

            conn.close();

        } catch (Exception e) {

            System.out.println("CONNECTION FAILED");

            e.printStackTrace();
        }
    }
}