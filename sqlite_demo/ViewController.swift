//
//  ViewController.swift
//  sqlite_demo
//
//  Created by Mac172 on 22/01/20.
//  Copyright © 2020 Mac172. All rights reserved.
//

import UIKit
import SQLite3
class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var imgpicker = UIImagePickerController()
    var dbpath : String = ""
    var dbobj : OpaquePointer?
    var photos : URL!
    var dataarr : [[String : String]] = []
    @IBOutlet var profile_img: UIImageView!
    @IBOutlet var name_txt: UITextField!
    @IBOutlet var age_txt: UITextField!
    @IBOutlet var in_btn: UIButton!
    @IBOutlet var list_tbl: UITableView!
    var imgName : String!
    var uid : Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        in_btn.layer.borderWidth = 1
        in_btn.layer.cornerRadius = 8
        in_btn.layer.borderColor = UIColor.white.cgColor
        
        // Register Custom Cell For List
        list_tbl.register(UINib(nibName: "ListTableViewCell", bundle: nil), forCellReuseIdentifier: "ListTableViewCell")
        
        do {
            let path = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fpath = path.appendingPathComponent("Photos")
            
            if(!FileManager.default.fileExists(atPath: fpath.path, isDirectory: .none)) {
                try FileManager.default.createDirectory(at: fpath, withIntermediateDirectories: false, attributes: nil)
            }
            
            let db = path.appendingPathComponent("Person.db")
            dbpath = db.path
            
            if(!FileManager.default.fileExists(atPath: db.path)) {
                FileManager.default.createFile(atPath: db.path, contents: nil, attributes: nil)
            }
            let path1 = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            
            photos = path1.appendingPathComponent("Photos")
            let createquery = "CREATE TABLE IF NOT EXISTS HUMAN(ID INTEGER PRIMARY KEY AUTOINCREMENT,NAME TEXT,AGE INTEGER,IMAGE TEXT)"
            fireQuery(qry: createquery, completion: nil)
            let selectData = "SELECT * FROM HUMAN"
            fireQuery(qry: selectData, completion: nil)
        } catch let err {
            print(err)
        }
    }
    
    
    func fireQuery(qry : String , completion :(() ->())?) {
        dataarr.removeAll()
        if(sqlite3_open(dbpath,&dbobj) == SQLITE_OK) {
            print("Open Database")
            var Statement: OpaquePointer?
            if sqlite3_prepare_v2(dbobj, qry, -1, &Statement, nil) == SQLITE_OK {
                while sqlite3_step(Statement) == SQLITE_ROW {
                    let pid = sqlite3_column_int(Statement, 0)
                    let pname = String(cString: sqlite3_column_text(Statement, 1))
                    let page = sqlite3_column_int(Statement, 2)
                    let pimg = String(cString: sqlite3_column_text(Statement, 3))
                    var temp_data = [String : String]()
                    temp_data["id"] = String(pid)
                    temp_data["name"] = pname
                    temp_data["age"] = String(page)
                    temp_data["img"] = pimg
                    self.dataarr.append(temp_data)
                }
            }
            sqlite3_finalize(Statement)
        }
        sqlite3_close(dbobj)
        if(completion != nil) {
            completion!()
        }
    }
    
    // Browser Image From Gallary
    @IBAction func browse_img(_ sender: Any) {
        let alert = UIAlertController(title: "Image", message: "Select option", preferredStyle: .alert)
        let photos = UIAlertAction(title: "Photo Libarary", style: .default) { (photo) in
            if(UIImagePickerController.isSourceTypeAvailable(.photoLibrary)) {
                self.imgpicker.delegate = self
                self.imgpicker.sourceType = .photoLibrary
                self.imgpicker.allowsEditing = true
                self.present(self.imgpicker, animated: true, completion: nil)
            }
            else {
                print("Not available")
            }
        }
        let camera = UIAlertAction(title: "Camera", style: .default) { (photo) in
            if(UIImagePickerController.isSourceTypeAvailable(.camera)) {
                self.imgpicker.delegate = self
                self.imgpicker.sourceType = .camera
                self.present(self.imgpicker, animated: true, completion: nil)
            }
            else {
                print("Camera Not available")
            }
        }
        let cancel = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        alert.addAction(photos)
        alert.addAction(camera)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            profile_img.image = image
        }
    }
    
    
    // Add & Update Btn Operation
    @IBAction func data_operation(_ sender: Any) {
        let btn = sender as! UIButton
        if btn.titleLabel?.text == "ADD" {
            if(self.profile_img.image != nil && self.name_txt.text != "" && self.age_txt.text != "") {
                do {
                    imgName = "\(name_txt.text!)\(age_txt.text!) \( Date())"
                    print(imgName!)
                    
                    let imgurl = photos.appendingPathComponent(imgName  + ".jpg")
                    let image =  self.profile_img.image
                    guard let imgdata = (image?.jpegData(compressionQuality: 1))  else {
                        return
                    }
                    try imgdata.write(to: imgurl)
                    let insertQuery = String("INSERT INTO HUMAN(NAME,AGE,IMAGE) VALUES('\(name_txt.text!)',\(Int(age_txt.text!)!),'\(imgName!).jpg')")
                    fireQuery(qry: insertQuery) {
                        let selectData = "SELECT * FROM HUMAN"
                        self.name_txt.text = ""
                        self.age_txt.text = ""
                        self.profile_img.image = UIImage(named: "person")
                        self.fireQuery(qry: selectData) {
                            self.list_tbl.reloadData()
                        }
                    }
                } catch let err {
                    print(err)
                }
            }
            else
            {
                let alert = UIAlertController(title: "Alert", message: "Please select profile image or Enter name or age", preferredStyle: .alert)
                let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alert.addAction(ok)
                self.present(alert, animated: true, completion: nil)
            }
        }
        else if in_btn.titleLabel?.text == "Update"
        {
            if(self.profile_img.image != nil && self.name_txt.text != "" && self.age_txt.text != "")
            {
                do {
                    imgName = "\(name_txt.text!)\(age_txt.text!) \( Date())"
                    print(imgName!)
                    
                    let imgurl = photos.appendingPathComponent(imgName  + ".jpg")
                    let image =  self.profile_img.image
                    guard let imgdata = (image?.jpegData(compressionQuality: 1))  else {
                        return
                    }
                    try imgdata.write(to: imgurl)
                    let updateData = "UPDATE HUMAN SET NAME = '\(name_txt.text!)', AGE = \(Int(age_txt.text!)!),IMAGE = '\(imgName!).jpg' WHERE ID = \(uid!)"
                    fireQuery(qry: updateData) {
                        let selectData = "SELECT * FROM HUMAN"
                        self.name_txt.text = ""
                        self.age_txt.text = ""
                        self.profile_img.image = UIImage(named: "person")
                        self.in_btn.setTitle("Insert", for: .normal)
                        self.fireQuery(qry: selectData) {
                            self.list_tbl.reloadData()
                        }
                    }
                }catch let err {
                    print(err)
                }
            }
            else {
                let alert = UIAlertController(title: "Alert", message: "Please select profile image or Enter name or age", preferredStyle: .alert)
                let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alert.addAction(ok)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}

//MARK: TableView Delegate & DataSource Methods
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataarr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ListTableViewCell", for: indexPath) as! ListTableViewCell
        
        do {
            let imgurl = photos.appendingPathComponent(dataarr[indexPath.row]["img"]!)
            let data = try Data(contentsOf: imgurl)
            
            if let img = UIImage.init(data: data) {
                cell.profileImageView.image = img
            }
            cell.imageView?.contentMode = .scaleAspectFill
            cell.nameLbl.text = dataarr[indexPath.row]["name"]
            cell.ageLbl.text = dataarr[indexPath.row]["age"]
        }
        catch let err {
            print(err)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        do {
            let imgurl = photos.appendingPathComponent(dataarr[indexPath.row]["img"]!)
            let data = try Data(contentsOf: imgurl)
            
            if let img = UIImage.init(data: data) {
                profile_img.image = img
            }
            name_txt.text = dataarr[indexPath.row]["name"]!
            age_txt.text = dataarr[indexPath.row]["age"]!
            in_btn.setTitle("Update", for: .normal)
            uid = Int(dataarr[indexPath.row]["id"]!)!
            print(uid!)
        } catch let err {
            print(err)
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if(editingStyle == .delete) {
            let deleteData = "DELETE FROM HUMAN WHERE ID = \(dataarr[indexPath.row]["id"]!)"
            fireQuery(qry: deleteData) {
                let selectData = "SELECT * FROM HUMAN"
                self.fireQuery(qry: selectData) {
                    self.list_tbl.reloadData()
                }
            }
        }
    }
}

