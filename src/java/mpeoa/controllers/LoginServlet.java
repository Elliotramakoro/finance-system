// src/java/mpeoa/controllers/LoginServlet.java
package mpeoa.controllers;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import mpeoa.dao.UserDAO;
import mpeoa.models.User;

@WebServlet("/login")
public class LoginServlet extends HttpServlet {
    
    private UserDAO userDAO;
    
    @Override
    public void init() throws ServletException {
        super.init();
        userDAO = new UserDAO();
        System.out.println("=== LoginServlet Initialized ===");
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (session != null && session.getAttribute("user") != null) {
            // Redirect based on role
            User user = (User) session.getAttribute("user");
            redirectBasedOnRole(response, user);
        } else {
            request.getRequestDispatcher("/views/login.jsp").forward(request, response);
        }
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String username = request.getParameter("username");
        String password = request.getParameter("password");
        String remember = request.getParameter("remember");
        String selectedRole = request.getParameter("role");
        
        System.out.println("=== Login Attempt ===");
        System.out.println("Username: " + username);
        System.out.println("Selected Role: " + selectedRole);
        
        // Validate input
        if (username == null || username.trim().isEmpty() ||
            password == null || password.trim().isEmpty()) {
            request.setAttribute("error", "Please enter username and password");
            request.getRequestDispatcher("/views/login.jsp").forward(request, response);
            return;
        }
        
        // Validate role selection
        if (selectedRole == null || selectedRole.trim().isEmpty()) {
            request.setAttribute("error", "Please select your role");
            request.getRequestDispatcher("/views/login.jsp").forward(request, response);
            return;
        }
        
        // Authenticate user from database
        User user = userDAO.authenticate(username, password);
        
        if (user != null) {
            System.out.println("User found - Role: " + user.getRoleName());
            
            // Check if selected role matches user's actual role
            if (!user.getRoleName().equalsIgnoreCase(selectedRole)) {
                System.out.println("Role mismatch! Selected: " + selectedRole + ", Actual: " + user.getRoleName());
                request.setAttribute("error", "Invalid role selected. This account is for: " + user.getRoleName());
                request.getRequestDispatcher("/views/login.jsp").forward(request, response);
                return;
            }
            
            System.out.println("Login SUCCESS for user: " + username);
            
            // Handle "Remember Me" functionality
            if (remember != null && remember.equals("on")) {
                jakarta.servlet.http.Cookie cookie = new jakarta.servlet.http.Cookie("remembered_username", username);
                cookie.setMaxAge(30 * 24 * 60 * 60); // 30 days
                cookie.setPath(request.getContextPath());
                response.addCookie(cookie);
                System.out.println("Remember me cookie set for: " + username);
            } else {
                // Remove cookie if exists
                jakarta.servlet.http.Cookie[] cookies = request.getCookies();
                if (cookies != null) {
                    for (jakarta.servlet.http.Cookie cookie : cookies) {
                        if ("remembered_username".equals(cookie.getName())) {
                            cookie.setMaxAge(0);
                            cookie.setPath(request.getContextPath());
                            response.addCookie(cookie);
                            System.out.println("Remember me cookie removed");
                            break;
                        }
                    }
                }
            }
            
            // Create session
            HttpSession session = request.getSession();
            session.setAttribute("user", user);
            session.setAttribute("userId", user.getUserId());
            session.setAttribute("username", user.getUsername());
            session.setAttribute("userFullName", user.getFullName());
            session.setAttribute("userRole", user.getRoleName());
            session.setAttribute("userRoleId", user.getRoleId());
            
            System.out.println("Session created for user: " + username);
            System.out.println("Redirecting based on role: " + user.getRoleName());
            
            // Redirect based on role
            redirectBasedOnRole(response, user);
            
        } else {
            System.out.println("Login FAILED for user: " + username);
            request.setAttribute("error", "Invalid username or password");
            request.getRequestDispatcher("/views/login.jsp").forward(request, response);
        }
    }
    
    private void redirectBasedOnRole(HttpServletResponse response, User user) throws IOException {
        String role = user.getRoleName().toLowerCase();
        String contextPath = getServletContext().getContextPath();
        
        System.out.println("=== Redirecting ===");
        System.out.println("Role: " + role);
        System.out.println("Context Path: " + contextPath);
        
        switch (role) {
            case "administrator":
                System.out.println("Redirecting to: " + contextPath + "/admin/dashboard");
                response.sendRedirect(contextPath + "/admin/dashboard");
                break;
            case "manager":
                System.out.println("Redirecting to: " + contextPath + "/manager/dashboard.jsp");
                response.sendRedirect(contextPath + "/manager/dashboard.jsp");
                break;
            case "accountant":
                System.out.println("Redirecting to: " + contextPath + "/accountant/dashboard.jsp");
                response.sendRedirect(contextPath + "/accountant/dashboard.jsp");
                break;
            case "cashier":
                System.out.println("Redirecting to: " + contextPath + "/cashier/dashboard.jsp");
                response.sendRedirect(contextPath + "/cashier/dashboard.jsp");
                break;
            case "inventory officer":
                System.out.println("Redirecting to: " + contextPath + "/inventory/dashboard.jsp");
                response.sendRedirect(contextPath + "/inventory/dashboard.jsp");
                break;
            default:
                System.out.println("Unknown role, redirecting to: " + contextPath + "/dashboard.jsp");
                response.sendRedirect(contextPath + "/dashboard.jsp");
                break;
        }
    }
}