// src/java/mpeoa/controllers/POSSaleServlet.java
package mpeoa.controllers;

import mpeoa.dao.SaleDAO;
import mpeoa.dao.ProductDAO;
import mpeoa.models.Sale;
import mpeoa.models.SaleItem;
import mpeoa.models.User;
import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/pos-sale")
public class POSSaleServlet extends HttpServlet {
    
    private SaleDAO saleDAO;
    private ProductDAO productDAO;
    
    @Override
    public void init() throws ServletException {
        super.init();
        saleDAO = new SaleDAO();
        productDAO = new ProductDAO();
        System.out.println("=== POSSaleServlet Initialized ===");
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            out.write("{\"success\": false, \"message\": \"Please login first\"}");
            return;
        }
        
        User loggedInUser = (User) session.getAttribute("user");
        String action = request.getParameter("action");
        
        System.out.println("=== POS Sale Request ===");
        System.out.println("Action: " + action);
        System.out.println("User: " + loggedInUser.getUsername());
        
        if ("processSale".equals(action)) {
            processSale(request, response, loggedInUser);
        } else {
            out.write("{\"success\": false, \"message\": \"Invalid action\"}");
        }
    }
    
    private void processSale(HttpServletRequest request, HttpServletResponse response, User user)
            throws IOException {
        
        PrintWriter out = response.getWriter();
        
        // Get parameters
        String[] productIds = request.getParameterValues("productId[]");
        String[] quantities = request.getParameterValues("quantity[]");
        String[] prices = request.getParameterValues("price[]");
        String paymentMethod = request.getParameter("paymentMethod");
        
        System.out.println("Product IDs count: " + (productIds != null ? productIds.length : 0));
        
        if (productIds == null || productIds.length == 0) {
            out.write("{\"success\": false, \"message\": \"No items in cart\"}");
            return;
        }
        
        try {
            Sale sale = new Sale();
            sale.setInvoiceNumber(generateInvoiceNumber());
            sale.setUserId(user.getUserId());
            sale.setPaymentMethod(paymentMethod != null ? paymentMethod : "Cash");
            sale.setDiscount(BigDecimal.ZERO);
            
            List<SaleItem> items = new ArrayList<>();
            BigDecimal totalAmount = BigDecimal.ZERO;
            
            for (int i = 0; i < productIds.length; i++) {
                int productId = Integer.parseInt(productIds[i]);
                int quantity = Integer.parseInt(quantities[i]);
                BigDecimal unitPrice = new BigDecimal(prices[i]);
                
                // Create SaleItem with constructor
                SaleItem item = new SaleItem(productId, quantity, unitPrice);
                items.add(item);
                
                totalAmount = totalAmount.add(item.getTotalPrice());
                System.out.println("Item " + i + ": Product " + productId + ", Qty " + quantity + ", Price " + unitPrice);
            }
            
            BigDecimal tax = totalAmount.multiply(new BigDecimal("0.15"));
            BigDecimal finalAmount = totalAmount.add(tax);
            
            sale.setTotalAmount(totalAmount);
            sale.setTax(tax);
            sale.setFinalAmount(finalAmount);
            sale.setItems(items);
            
            System.out.println("Total: " + totalAmount + ", Tax: " + tax + ", Final: " + finalAmount);
            
            boolean success = saleDAO.createSale(sale);
            
            if (success) {
                System.out.println("Sale created! Invoice: " + sale.getInvoiceNumber());
                out.write("{\"success\": true, \"invoiceNumber\": \"" + sale.getInvoiceNumber() + "\"}");
            } else {
                System.out.println("Failed to create sale");
                out.write("{\"success\": false, \"message\": \"Database error - failed to create sale\"}");
            }
            
        } catch (NumberFormatException e) {
            System.out.println("Number format error: " + e.getMessage());
            out.write("{\"success\": false, \"message\": \"Invalid number format: " + e.getMessage() + "\"}");
        } catch (Exception e) {
            System.out.println("Error processing sale: " + e.getMessage());
            e.printStackTrace();
            out.write("{\"success\": false, \"message\": \"Error: " + e.getMessage() + "\"}");
        }
    }
    
    private String generateInvoiceNumber() {
        return "INV-" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"));
    }
}