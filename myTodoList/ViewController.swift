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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let sheet = UIAlertController(title: "Edit", message: nil, preferredStyle: .actionSheet)
        let item = models[indexPath.row]
        
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        sheet.addAction(UIAlertAction(title: "Edit", style: .default, handler: { [weak self] _ in
            
            let alert = UIAlertController(title: "Edit Item", message: "Edit your item", preferredStyle: .alert)
            
            alert.addTextField(configurationHandler: nil)
            alert.textFields?.first?.text = item.name
            alert.addAction(UIAlertAction(title: "Submit", style: .cancel, handler: { [weak self] _ in
                guard let field = alert.textFields?.first, let newName = field.text, !newName.isEmpty else {
                    return
                }
                
                self?.updateItem(item: item, index: indexPath.row ,newName: newName)
                
            }))
            self?.present(alert, animated: true)
        }))
        sheet.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            self?.deleteItem(index: indexPath.row)
        }))
        present(sheet, animated: true)
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
        let newItem = Todos(createAt: convertDate, name: newName)
        self.models.append(newItem)
        self.ref.child("TodoList").setValue(convertToArray(todos:models))
        
        getAllItems()
    }
    
    func deleteItem(index: Int) {
        self.models.remove(at: index)
        self.ref.child("TodoList").setValue(convertToArray(todos:models))
        getAllItems()
        }

    func updateItem(item:Todos, index: Int, newName: String) {
        let editItem = Todos(createAt: item.createAt, name: newName)
        self.models[index] = editItem
        self.ref.child("TodoList").setValue(convertToArray(todos:models))
        getAllItems()
    }
        
    func convertToArray(todos: [Todos]) -> Array<Any> {
        var newItemArray:Array = [Dictionary<String, Any>]()
        
        for index in 0..<todos.count{
            let content = todos[index].name
            let date = todos[index].createAt
            newItemArray.append(["createAt":date, "name":content])
        }
        return newItemArray
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

