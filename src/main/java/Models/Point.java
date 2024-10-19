/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package Models;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;

/**
 *
 * @author Quoc Anh
 */
public class Point {

    private int point_id;
    private int customer_id;
    private int point;

    public Point() {
    }
    
    public Point(int point_id, int customer_id, int point) {
        this.point_id = point_id;
        this.customer_id = customer_id;
        this.point = point;
    }
    
    public Point(int customer_id, int point ) {
        this.customer_id = customer_id;
        this.point = point;
    }

    public int getPoint_id() {
        return point_id;
    }

    public void setPoint_id(int point_id) {
        this.point_id = point_id;
    }

    public int getCustomer_id() {
        return customer_id;
    }

    public void setCustomer_id(int customer_id) {
        this.customer_id = customer_id;
    }

    public int getPoint() {
        return point;
    }

    public void setPoint(int point) {
        this.point = point;
    }
}
