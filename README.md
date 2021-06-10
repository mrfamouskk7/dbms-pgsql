## Library Management System using Postgresql 📚

There are 4 Tables: 📑
* ```Book_details:``` Contains all book details
* ```Member_details:``` Contains all Member details
* ```Boorrower_details:``` Contains details of borrowed books and their temporary owners 
* ```Reserve:``` Contains details of reserved book and member who reserved it 
<br><br>

Contains functions and triggers: 📘
* ```borrow_procedure():``` Takes care of updating all the data when someone borrows a book
* ```borrow_returned():``` Takes care of updating all the data when someone returns a book
* ```reserve_book():``` Updates reserve table depending on number of copies of books left
