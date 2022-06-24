//  Created by 신승재 on 2022/06/22.

import UIKit
import FirebaseDatabase

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var ref: DatabaseReference!
    
    
    @IBOutlet weak var tableView: UITableView!

    private var models = [Todos]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        title = "Todo List"
        
        getAllItems()
        tableView.delegate = self
        tableView.dataSource = self
        
    }
    
    
    @IBAction func pushAddButton(_ sender: Any) {
        let alert = UIAlertController(title: "New Item", message: "Enter new item", preferredStyle: .alert)
               
               alert.addTextField(configurationHandler: nil)
               alert.addAction(UIAlertAction(title: "Submit", style: .cancel, handler: { [weak self] _ in
                   guard let field = alert.textFields?.first, let text = field.text, !text.isEmpty else {
                       return
                   }
                   
                   self?.createItem(name: text)
                   
               }))
               present(alert, animated: true)
    }
    
    // tableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = models[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableViewCell
        
        cell.name.text = model.name
        cell.createAt.text = model.createAt
                
        return cell
    }
    
    
    // realtime database
    func getAllItems() {
        ref.child("TodoList").getData(completion:  { error, snapshot in
          guard error == nil else {
            print(error!.localizedDescription)
            return
          }
            
            do {
                let data = try JSONSerialization.data(withJSONObject: snapshot?.value as Any, options: [])
                let decoder = JSONDecoder()
                self.models = try decoder.decode([Todos].self, from: data)
                DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
            }
            catch let error {
                // error 처리
                print("---> error \(error.localizedDescription)")
            }
        });
    }
    
    func createItem(name: String) {
        let newName = name
        let nowDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 MM월 dd일"
        let convertDate = dateFormatter.string(from: nowDate)
        
        
        // update database
        let key = self.models.count
        let newItem = ["createAt":convertDate, "name":newName]
        let childUpdates = ["/TodoList/\(key)": newItem]
        ref.updateChildValues(childUpdates)
        getAllItems()

    }
        
       
    
    // JSON Data Parsing
    struct Todos: Codable {
        let createAt:String
        let name:String
        var toDictionary: [String:Any] {
            return ["name" : name, "createAt" : createAt]
        }
    }
    
}

