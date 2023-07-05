-- Eti Kroitoro
-- 15.05.2023
-- project 2 - Advanced SQL 


--ex1
select p.ProductID,p.Name,p.Color,p.ListPrice,p.Size , sod.ProductID
from 
Production.Product as p left outer join sales.SalesOrderDetail as sod
on p.ProductID=sod.ProductID
where sod.ProductID is null

--- another solution to ex1

select p.ProductID,p.Name,p.Color,p.ListPrice,p.Size 
from 
Production.Product as p 
where not exists (select p.ProductID from sales.SalesOrderDetail as sod where p.ProductID=sod.ProductID)

--ex2

update sales.customer 
set personid=customerid     
where customerid <=290  

update sales.customer 
set personid=customerid+1700     
where customerid >= 300 and customerid<=350  

update sales.customer 
set personid=customerid+1700     
where customerid >= 352 and customerid<=701

select  c.CustomerID, isnull (p.FirstName,'unknown'), isnull(p.LastName,'unknown')
from sales.Customer as c left outer join Person.Person as p on c.CustomerID=p.BusinessEntityID
left outer join sales.SalesOrderHeader as soh
on c.CustomerID = soh.CustomerID
where soh.SalesOrderID is null 

--ex3
with cte
as
(select soh.CustomerID,p.LastName,p.FirstName,
count (soh.SalesOrderID) as [count of orders]
from sales.SalesOrderHeader as soh
join sales.Customer as c
on c.CustomerID = soh.CustomerID
join person.Person as p
on c.PersonID = p.BusinessEntityID
group by soh.CustomerID, p.LastName,p.FirstName)

select top(10)cte.CustomerID,cte.LastName,cte.FirstName, cte.[count of orders]
from cte
order by [count of orders] desc

--- another solution to ex3

select soh.CustomerID,p.LastName,p.FirstName,
count (soh.SalesOrderID) as [count of orders]
from sales.SalesOrderHeader as soh
join sales.Customer as c
on c.CustomerID = soh.CustomerID
join person.Person as p
on c.PersonID = p.BusinessEntityID
group by soh.CustomerID, p.LastName,p.FirstName
order by count (soh.SalesOrderID) desc
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY

--ex4

select p.FirstName,p.LastName,e.JobTitle,e.HireDate ,
count(*) over (partition by e.JobTitle) as [count of title]
from HumanResources.Employee as e
join Person.Person as p
on e.BusinessEntityID = p.BusinessEntityID

--ex5
go 

with cte
as
(select soh.SalesOrderID,soh.CustomerID, soh.OrderDate as [last order],p.LastName,p.FirstName,
ROW_NUMBER ()over (partition by soh.CustomerID order by soh.OrderDate desc) as rowNUm,
lead (soh.OrderDate,1) over (partition by soh.CustomerID order by soh.OrderDate desc) as PreviousOrder
from sales.SalesOrderHeader as soh
join Sales.Customer as c
on soh.CustomerID = c.CustomerID
join Person.Person as p
on c.PersonID = p.BusinessEntityID)

select cte.SalesOrderID,cte.CustomerID,cte.LastName,cte.FirstName,cte.[last order],cte.PreviousOrder from cte
where cte.rowNUm = 1
order by cte.CustomerID

--ex6
go 

with cte1
as
(select sod.SalesOrderID ,year (soh.OrderDate) as year, p.LastName,p.FirstName,
cast(sum (sod.LineTotal)as money) as total,
row_number () over (partition by year (soh.OrderDate) order by sum (sod.LineTotal) desc) as rank
from sales.SalesOrderDetail as sod
join sales.SalesOrderHeader as soh
on sod.SalesOrderID = soh.SalesOrderID
join sales.Customer as c
on c.CustomerID = soh.CustomerID
join Person.Person as p
on p.BusinessEntityID = c.PersonID
group by year (soh.OrderDate) , sod.SalesOrderID,p.LastName,p.FirstName)

select cte1.year,cte1.SalesOrderID,cte1.LastName,cte1.FirstName,cte1.total from cte1
where rank = 1

--ex7
go

select * 
from(select year(soh.OrderDate) as YY, month(soh.OrderDate) as MM, soh.SalesOrderID
from sales.SalesOrderHeader as soh) as sohh
pivot (count(SalesOrderID)for YY in ([2011],[2012],[2013],[2014]))as pvt
order by MM

--ex8
go

with cte
as
(select year(soh.OrderDate) as year, MONTH (soh.OrderDate) as month,
sum(soh.SubTotal) as sumorder
from sales.SalesOrderHeader as soh
group by year(soh.OrderDate),MONTH (soh.OrderDate)
)
,
cte1
as
(select 
cast(cte.year as varchar(15)) as year,
cast (cte.month as varchar(15)) as month , cte.sumorder,
sum (cte.sumorder) over (partition by cte.year order by cte.month) as summiz,
row_number () over (partition by cte.year order by cte.month) as rn -- for sorting
from cte
union
select year(soh.OrderDate) Year,'total', null,
sum(soh.SubTotal),13
 from Sales.SalesOrderHeader soh
 group by  year(soh.OrderDate)
 union
select 2014,'grand total' as month,null, sum(soh.SubTotal) as summiz,200
from sales.SalesOrderHeader as soh
)

select cte1.year,cte1.month,format(cte1.sumorder,'c','en-us')as sumorder,format(cte1.summiz ,'c','en-us') as summiz
from cte1
order by cte1.year,cte1.rn



--ex 9
go

with cte
as
(select d.Name, e.BusinessEntityID, concat(p.FirstName,' ',p.MiddleName,' ',p.LastName) as 'Full Name',
e.HireDate,datediff(month,e.HireDate,getdate())  as 'seniority' ,
LEAD(e.HireDate) over (partition by d.Name order by e.HireDate desc) as 'previous emp. Hdate',
LEAD(concat(p.FirstName,' ',p.MiddleName,' ',p.LastName)) over (partition by d.Name order by e.HireDate desc) as 'previous emp. name',
datediff(DAY,LEAD(e.HireDate) over (partition by d.Name order by e.HireDate desc),e.HireDate)  as 'Diff Days' ,
ROW_NUMBER ()over (partition by d.Name order by e.HireDate desc) as rowNUm
from HumanResources.Employee as e
join HumanResources.EmployeeDepartmentHistory as edh
on e.BusinessEntityID=edh.BusinessEntityID 
join HumanResources.Department as d
on edh.DepartmentID = d.DepartmentID
join Person.Person as p
on e.BusinessEntityID = p.BusinessEntityID
where d.Name is not null and edh.EndDate is null
)

select cte.Name,cte.BusinessEntityID,cte.[Full Name],cte.HireDate,cte.seniority,cte.[previous emp. name],
cte.[previous emp. Hdate],cte.[Diff Days]
from cte

--ex 10


select edh.StartDate, edh.DepartmentID, stuff (((select ',' + cast(p2.BusinessEntityID as nvarchar(5))+ ' ' + p2.FirstName + ' '+ p2.LastName
from Person.Person as p2 join
HumanResources.EmployeeDepartmentHistory as edh2
on edh2.BusinessEntityID=p2.BusinessEntityID
where edh.StartDate = edh2.StartDate and edh.DepartmentID = edh2.DepartmentID
for xml path (''))),1,1,'') as emp_names
from HumanResources.EmployeeDepartmentHistory as edh
where edh.EndDate is null
group by edh.StartDate, edh.DepartmentID


