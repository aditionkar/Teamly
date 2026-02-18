//
//  IndianCity.swift
//  Teamly-backend
//
//  Created by user@37 on 18/02/26.
//

import Foundation

// MARK: - City Model

struct IndianCity {
    let name: String
    let state: String
}

// MARK: - Indian Cities Data

struct IndianCitiesData {
    static let all: [IndianCity] = [
        // Major Metropolitan Cities
        IndianCity(name: "Mumbai", state: "Maharashtra"),
        IndianCity(name: "Delhi", state: "Delhi"),
        IndianCity(name: "Bangalore", state: "Karnataka"),
        IndianCity(name: "Hyderabad", state: "Telangana"),
        IndianCity(name: "Ahmedabad", state: "Gujarat"),
        IndianCity(name: "Chennai", state: "Tamil Nadu"),
        IndianCity(name: "Kolkata", state: "West Bengal"),
        IndianCity(name: "Pune", state: "Maharashtra"),
        IndianCity(name: "Jaipur", state: "Rajasthan"),
        IndianCity(name: "Surat", state: "Gujarat"),
        
        // State Capitals & Major Cities
        IndianCity(name: "Lucknow", state: "Uttar Pradesh"),
        IndianCity(name: "Kanpur", state: "Uttar Pradesh"),
        IndianCity(name: "Nagpur", state: "Maharashtra"),
        IndianCity(name: "Patna", state: "Bihar"),
        IndianCity(name: "Indore", state: "Madhya Pradesh"),
        IndianCity(name: "Thane", state: "Maharashtra"),
        IndianCity(name: "Bhopal", state: "Madhya Pradesh"),
        IndianCity(name: "Visakhapatnam", state: "Andhra Pradesh"),
        IndianCity(name: "Vadodara", state: "Gujarat"),
        IndianCity(name: "Ghaziabad", state: "Uttar Pradesh"),
        IndianCity(name: "Ludhiana", state: "Punjab"),
        IndianCity(name: "Agra", state: "Uttar Pradesh"),
        IndianCity(name: "Nashik", state: "Maharashtra"),
        IndianCity(name: "Faridabad", state: "Haryana"),
        IndianCity(name: "Meerut", state: "Uttar Pradesh"),
        IndianCity(name: "Rajkot", state: "Gujarat"),
        IndianCity(name: "Varanasi", state: "Uttar Pradesh"),
        IndianCity(name: "Srinagar", state: "Jammu and Kashmir"),
        IndianCity(name: "Aurangabad", state: "Maharashtra"),
        IndianCity(name: "Dhanbad", state: "Jharkhand"),
        IndianCity(name: "Amritsar", state: "Punjab"),
        IndianCity(name: "Navi Mumbai", state: "Maharashtra"),
        IndianCity(name: "Allahabad", state: "Uttar Pradesh"),
        IndianCity(name: "Prayagraj", state: "Uttar Pradesh"),
        IndianCity(name: "Ranchi", state: "Jharkhand"),
        IndianCity(name: "Howrah", state: "West Bengal"),
        IndianCity(name: "Coimbatore", state: "Tamil Nadu"),
        IndianCity(name: "Jabalpur", state: "Madhya Pradesh"),
        IndianCity(name: "Gwalior", state: "Madhya Pradesh"),
        IndianCity(name: "Vijayawada", state: "Andhra Pradesh"),
        IndianCity(name: "Jodhpur", state: "Rajasthan"),
        IndianCity(name: "Madurai", state: "Tamil Nadu"),
        IndianCity(name: "Raipur", state: "Chhattisgarh"),
        IndianCity(name: "Kota", state: "Rajasthan"),
        IndianCity(name: "Chandigarh", state: "Chandigarh"),
        IndianCity(name: "Guwahati", state: "Assam"),
        IndianCity(name: "Solapur", state: "Maharashtra"),
        IndianCity(name: "Hubli", state: "Karnataka"),
        IndianCity(name: "Mysore", state: "Karnataka"),
        IndianCity(name: "Tiruchirappalli", state: "Tamil Nadu"),
        
        // Tier 2 Cities
        IndianCity(name: "Bareilly", state: "Uttar Pradesh"),
        IndianCity(name: "Aligarh", state: "Uttar Pradesh"),
        IndianCity(name: "Tiruppur", state: "Tamil Nadu"),
        IndianCity(name: "Moradabad", state: "Uttar Pradesh"),
        IndianCity(name: "Jalandhar", state: "Punjab"),
        IndianCity(name: "Bhubaneswar", state: "Odisha"),
        IndianCity(name: "Salem", state: "Tamil Nadu"),
        IndianCity(name: "Warangal", state: "Telangana"),
        IndianCity(name: "Guntur", state: "Andhra Pradesh"),
        IndianCity(name: "Bhiwandi", state: "Maharashtra"),
        IndianCity(name: "Saharanpur", state: "Uttar Pradesh"),
        IndianCity(name: "Gorakhpur", state: "Uttar Pradesh"),
        IndianCity(name: "Bikaner", state: "Rajasthan"),
        IndianCity(name: "Amravati", state: "Maharashtra"),
        IndianCity(name: "Noida", state: "Uttar Pradesh"),
        IndianCity(name: "Jamshedpur", state: "Jharkhand"),
        IndianCity(name: "Bhilai", state: "Chhattisgarh"),
        IndianCity(name: "Cuttack", state: "Odisha"),
        IndianCity(name: "Firozabad", state: "Uttar Pradesh"),
        IndianCity(name: "Kochi", state: "Kerala"),
        IndianCity(name: "Nellore", state: "Andhra Pradesh"),
        IndianCity(name: "Bhavnagar", state: "Gujarat"),
        IndianCity(name: "Dehradun", state: "Uttarakhand"),
        IndianCity(name: "Durgapur", state: "West Bengal"),
        IndianCity(name: "Asansol", state: "West Bengal"),
        IndianCity(name: "Rourkela", state: "Odisha"),
        IndianCity(name: "Nanded", state: "Maharashtra"),
        IndianCity(name: "Kolhapur", state: "Maharashtra"),
        IndianCity(name: "Ajmer", state: "Rajasthan"),
        IndianCity(name: "Akola", state: "Maharashtra"),
        IndianCity(name: "Gulbarga", state: "Karnataka"),
        IndianCity(name: "Jamnagar", state: "Gujarat"),
        IndianCity(name: "Ujjain", state: "Madhya Pradesh"),
        IndianCity(name: "Loni", state: "Uttar Pradesh"),
        IndianCity(name: "Siliguri", state: "West Bengal"),
        IndianCity(name: "Jhansi", state: "Uttar Pradesh"),
        IndianCity(name: "Ulhasnagar", state: "Maharashtra"),
        IndianCity(name: "Jammu", state: "Jammu and Kashmir"),
        IndianCity(name: "Sangli", state: "Maharashtra"),
        IndianCity(name: "Mangalore", state: "Karnataka"),
        IndianCity(name: "Erode", state: "Tamil Nadu"),
        IndianCity(name: "Belgaum", state: "Karnataka"),
        IndianCity(name: "Ambattur", state: "Tamil Nadu"),
        IndianCity(name: "Tirunelveli", state: "Tamil Nadu"),
        IndianCity(name: "Malegaon", state: "Maharashtra"),
        IndianCity(name: "Gaya", state: "Bihar"),
        IndianCity(name: "Jalgaon", state: "Maharashtra"),
        IndianCity(name: "Udaipur", state: "Rajasthan"),
        IndianCity(name: "Maheshtala", state: "West Bengal"),
        
        // Kerala Cities
        IndianCity(name: "Thiruvananthapuram", state: "Kerala"),
        IndianCity(name: "Kozhikode", state: "Kerala"),
        IndianCity(name: "Kollam", state: "Kerala"),
        IndianCity(name: "Thrissur", state: "Kerala"),
        
        // Karnataka Cities
        IndianCity(name: "Davanagere", state: "Karnataka"),
        IndianCity(name: "Bellary", state: "Karnataka"),
        IndianCity(name: "Bijapur", state: "Karnataka"),
        IndianCity(name: "Shivamogga", state: "Karnataka"),
        IndianCity(name: "Tumkur", state: "Karnataka"),
        
        // Andhra Pradesh & Telangana
        IndianCity(name: "Kurnool", state: "Andhra Pradesh"),
        IndianCity(name: "Rajahmundry", state: "Andhra Pradesh"),
        IndianCity(name: "Kadapa", state: "Andhra Pradesh"),
        IndianCity(name: "Kakinada", state: "Andhra Pradesh"),
        IndianCity(name: "Eluru", state: "Andhra Pradesh"),
        IndianCity(name: "Tenali", state: "Andhra Pradesh"),
        IndianCity(name: "Tirupati", state: "Andhra Pradesh"),
        IndianCity(name: "Chittoor", state: "Andhra Pradesh"),
        IndianCity(name: "Anantapur", state: "Andhra Pradesh"),
        IndianCity(name: "Proddatur", state: "Andhra Pradesh"),
        IndianCity(name: "Nizamabad", state: "Telangana"),
        IndianCity(name: "Khammam", state: "Telangana"),
        IndianCity(name: "Karimnagar", state: "Telangana"),
        IndianCity(name: "Ramagundam", state: "Telangana"),
        
        // West Bengal
        IndianCity(name: "Rajpur Sonarpur", state: "West Bengal"),
        IndianCity(name: "South Dumdum", state: "West Bengal"),
        IndianCity(name: "Bhatpara", state: "West Bengal"),
        IndianCity(name: "Panihati", state: "West Bengal"),
        IndianCity(name: "Kamarhati", state: "West Bengal"),
        IndianCity(name: "Bardhaman", state: "West Bengal"),
        IndianCity(name: "Kulti", state: "West Bengal"),
        IndianCity(name: "Bally", state: "West Bengal"),
        IndianCity(name: "Barasat", state: "West Bengal"),
        IndianCity(name: "North Dumdum", state: "West Bengal"),
        IndianCity(name: "Baranagar", state: "West Bengal"),
        IndianCity(name: "Habra", state: "West Bengal"),
        IndianCity(name: "Kharagpur", state: "West Bengal"),
        
        // Bihar & Jharkhand
        IndianCity(name: "Bokaro", state: "Jharkhand"),
        IndianCity(name: "Mango", state: "Jharkhand"),
        IndianCity(name: "Bhagalpur", state: "Bihar"),
        IndianCity(name: "Muzaffarpur", state: "Bihar"),
        IndianCity(name: "Bihar Sharif", state: "Bihar"),
        IndianCity(name: "Darbhanga", state: "Bihar"),
        IndianCity(name: "Purnia", state: "Bihar"),
        IndianCity(name: "Arrah", state: "Bihar"),
        IndianCity(name: "Begusarai", state: "Bihar"),
        
        // Madhya Pradesh & Chhattisgarh
        IndianCity(name: "Sambalpur", state: "Odisha"),
        IndianCity(name: "Bilaspur", state: "Chhattisgarh"),
        IndianCity(name: "Korba", state: "Chhattisgarh"),
        IndianCity(name: "Durg", state: "Chhattisgarh"),
        IndianCity(name: "Raigarh", state: "Chhattisgarh"),
        IndianCity(name: "Dewas", state: "Madhya Pradesh"),
        IndianCity(name: "Satna", state: "Madhya Pradesh"),
        IndianCity(name: "Ratlam", state: "Madhya Pradesh"),
        IndianCity(name: "Sagar", state: "Madhya Pradesh"),
        
        // Rajasthan
        IndianCity(name: "Bharatpur", state: "Rajasthan"),
        IndianCity(name: "Sikar", state: "Rajasthan"),
        IndianCity(name: "Pali", state: "Rajasthan"),
        IndianCity(name: "Bhilwara", state: "Rajasthan"),
        IndianCity(name: "Alwar", state: "Rajasthan"),
        
        // Punjab & Haryana
        IndianCity(name: "Patiala", state: "Punjab"),
        IndianCity(name: "Bathinda", state: "Punjab"),
        IndianCity(name: "Rohtak", state: "Haryana"),
        IndianCity(name: "Panipat", state: "Haryana"),
        IndianCity(name: "Karnal", state: "Haryana"),
        IndianCity(name: "Sonipat", state: "Haryana"),
        
        // Tamil Nadu
        IndianCity(name: "Vellore", state: "Tamil Nadu"),
        IndianCity(name: "Thoothukudi", state: "Tamil Nadu"),
        IndianCity(name: "Dindigul", state: "Tamil Nadu"),
        IndianCity(name: "Tiruvottiyur", state: "Tamil Nadu"),
        IndianCity(name: "Avadi", state: "Tamil Nadu"),
        IndianCity(name: "Neyveli", state: "Tamil Nadu"),
        
        // Uttar Pradesh
        IndianCity(name: "Shahjahanpur", state: "Uttar Pradesh"),
        IndianCity(name: "Rampur", state: "Uttar Pradesh"),
        IndianCity(name: "Muzaffarnagar", state: "Uttar Pradesh"),
        IndianCity(name: "Mathura", state: "Uttar Pradesh"),
        IndianCity(name: "Unnao", state: "Uttar Pradesh"),
        IndianCity(name: "Farrukhabad", state: "Uttar Pradesh"),
        IndianCity(name: "Etawah", state: "Uttar Pradesh"),
        IndianCity(name: "Hapur", state: "Uttar Pradesh"),
        IndianCity(name: "Gonda", state: "Uttar Pradesh"),
        IndianCity(name: "Mau", state: "Uttar Pradesh"),
        
        // Maharashtra
        IndianCity(name: "Latur", state: "Maharashtra"),
        IndianCity(name: "Dhule", state: "Maharashtra"),
        IndianCity(name: "Ahmednagar", state: "Maharashtra"),
        IndianCity(name: "Chandrapur", state: "Maharashtra"),
        IndianCity(name: "Parbhani", state: "Maharashtra"),
        IndianCity(name: "Ichalkaranji", state: "Maharashtra"),
        IndianCity(name: "Jalna", state: "Maharashtra"),
        IndianCity(name: "Ambarnath", state: "Maharashtra"),
        IndianCity(name: "Satara", state: "Maharashtra"),
        
        // Gujarat
        IndianCity(name: "Junagadh", state: "Gujarat"),
        IndianCity(name: "Gandhidham", state: "Gujarat"),
        IndianCity(name: "Gandhinagar", state: "Gujarat"),
        IndianCity(name: "Porbandar", state: "Gujarat"),
        IndianCity(name: "Bhuj", state: "Gujarat"),
        
        // Odisha
        IndianCity(name: "Berhampur", state: "Odisha"),
        
        // Union Territories & NE States
        IndianCity(name: "Puducherry", state: "Puducherry"),
        IndianCity(name: "Ozhukarai", state: "Puducherry"),
        IndianCity(name: "Aizawl", state: "Mizoram"),
        IndianCity(name: "Imphal", state: "Manipur"),
        IndianCity(name: "Shillong", state: "Meghalaya"),
        IndianCity(name: "Silchar", state: "Assam"),
        IndianCity(name: "Dibrugarh", state: "Assam"),
        IndianCity(name: "Agartala", state: "Tripura"),
        IndianCity(name: "Gangtok", state: "Sikkim"),
        IndianCity(name: "Itanagar", state: "Arunachal Pradesh"),
        IndianCity(name: "Kohima", state: "Nagaland"),
        
        // Delhi NCR
        IndianCity(name: "New Delhi", state: "Delhi"),
        IndianCity(name: "Kirari Suleman Nagar", state: "Delhi"),
        
        // Uttarakhand & Himachal
        IndianCity(name: "Shimla", state: "Himachal Pradesh"),
        
        // Small UTs
        IndianCity(name: "Port Blair", state: "Andaman and Nicobar Islands"),
        IndianCity(name: "Silvassa", state: "Dadra and Nagar Haveli"),
        IndianCity(name: "Daman", state: "Daman and Diu"),
        IndianCity(name: "Diu", state: "Daman and Diu"),
        IndianCity(name: "Kavaratti", state: "Lakshadweep")
    ]
}
