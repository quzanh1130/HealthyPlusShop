/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package DAOs;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;
import Models.Point;
import java.util.ArrayList;
import java.util.List;

public class PointDAO {

    private Connection conn;
    private PreparedStatement ps;
    private ResultSet rs;

    public PointDAO() {
        conn = DBConnection.DBConnection.getConnection();
    }

    public ResultSet getAll() {
        String sql = "select * from Point";
        try {
            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();
            return rs;
        } catch (SQLException ex) {
            Logger.getLogger(PointDAO.class.getName()).log(Level.SEVERE, null, ex);
        }
        return null;
    }
    

    public Point getPoint(int id) {
        Point point = null;
        try {
            ps = conn.prepareStatement("select * from Point where customer_id = ?");
            ps.setInt(1, id);
            rs = ps.executeQuery();
            if (rs.next()) {
                point = new Point(rs.getInt("point_id"), rs.getInt("customer_id"), rs.getInt("point"));
            }
        } catch (SQLException ex) {
            Logger.getLogger(PointDAO.class.getName()).log(Level.SEVERE, null, ex);
        }
        return point;
    }
    
    public List<Point> getAllList() {
        ResultSet pointRS = this.getAll();
        List<Point> pointList = new ArrayList<>();
        try {
            while (pointRS.next()) {
                Point point = new Point(
                        pointRS.getInt("point_id"),
                        pointRS.getInt("customer_id"),     
                        pointRS.getInt("point")
                );                
                pointList.add(point);
            }
        } catch (SQLException ex) {
            Logger.getLogger(PointDAO.class.getName()).log(Level.SEVERE, null, ex);
        }
        return pointList;
    }

    public int add(Point point) {
        String sql = "insert into Point values (?,?)";
        int result = 0;
        try {
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, point.getCustomer_id());
            ps.setInt(2, point.getPoint());
            result = ps.executeUpdate();
        } catch (SQLException ex) {
            Logger.getLogger(PointDAO.class.getName()).log(Level.SEVERE, null, ex);
        }
        return result;
    }


    public int updatePoint(Point point) {
        String sql = "update [Point] SET point = point + ? WHERE customer_id = ?";
        int result = 0;
        try {
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, point.getPoint());   
            ps.setInt(2, point.getCustomer_id());
            result = ps.executeUpdate();
        } catch (SQLException ex) {
            Logger.getLogger(PointDAO.class.getName()).log(Level.SEVERE, null, ex);
        }
        return result;
    }
}
