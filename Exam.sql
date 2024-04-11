    /*FINAL EXAM*/
    
    /*1*/

/*
Query 1 : Total revenue per year
2 : create subquery with previous year and join on year = previous_year + 1
3 : Compute the percentage change with LAG function
4 : Use of COALESCE to get 'Not available'
*/
 
SELECT 
    CAST(strftime('%Y',InvoiceDate) AS INT) as Year,
    Sum(Total) as TotalRevenue,
    COALESCE(
            100.0 * ((1.0 * Sum(Total) / LAG(Sum(Total)) 
            OVER (ORDER BY CAST(strftime('%Y',InvoiceDate) AS INT))) - 1),
            'Not Available')
            as percent_change
FROM invoices 
GROUP BY year
;

    /*2*/

/*
Query 1 : Find the employees with wrong number format
2 : Calculate %
3: print in right format
*/
 SELECT 
     Nb_Employees_With_Wrong_Phone_Number, 
     Nb_Employees, 
     (printf('%.2f%%', (Nb_Employees_With_Wrong_Phone_Number * 100.0 / Nb_Employees))) as 'Percentage_Employees_With_Wrong_Phone_Number'
 FROM (   
        SELECT 
            (SELECT COUNT(EmployeeId) 
            FROM employees
            WHERE Phone NOT LIKE '%+%') as Nb_Employees_With_Wrong_Phone_Number,
            COUNT(EmployeeId) as Nb_Employees
        FROM employees
    )

;
    /*3*/

/*
Query 1 : separate business and personal accounts with case when
Associate the charge to the kinds of account
*/
SELECT CASE WHEN company is null
            THEN 'personal'
            ELSE 'business'
        END as Account_Type,
        Count(distinct customerid) as 'Nb_Accounts',
        CASE WHEN company is null
            THEN '99.99'
            ELSE '299.99'
    END as Subscription_Charges
FROM customers
GROUP BY Account_Type
;
    /*4*/

/*
Query 1 : Select top 5 artist ids with most revenues in 2012
2 :Same for 2013  
3 : exclude from the 2013 list the top 5 from 2012
*/
SELECT 
    art.artistid as ArtistId2013, 
    art.name as ArtistName2013, 
    Sum(ii.UnitPrice * ii.Quantity) as TotalRevenues2013
FROM 
    artists art, 
    albums alb, 
    tracks t, 
    invoice_items ii, 
    invoices i
WHERE 
    alb.artistid = art.artistid AND
    t.albumid = alb.albumid AND
    ii.trackid = t.trackid AND
    i.invoiceid = ii.invoiceid AND
    strftime('%Y',i.invoiceDate) = '2013' AND
    ArtistId2013 NOT IN
        (SELECT Artistid2012 
            FROM (                  
                    SELECT art.artistid as Artistid2012, Sum(ii.UnitPrice * ii.Quantity) as TotalRevenues2012
                    FROM artists art, albums alb, tracks t, invoice_items ii, invoices i
                    WHERE 
                        alb.artistid = art.artistid AND
                        t.albumid = alb.albumid AND
                        ii.trackid = t.trackid AND
                        i.invoiceid = ii.invoiceid AND
                        strftime('%Y',i.invoiceDate) = '2012'
                    GROUP BY Artistid2012
                    ORDER BY TotalRevenues2012 DESC
                    LIMIT 5
                )
            )
GROUP BY ArtistId2013
ORDER BY TotalRevenues2013 DESC
LIMIT 5

;

    /*5*/

/*
Query 1 : Artists w + 10 tracks sold
2 : compute total nb of seconds of tracks sold
3: compute bonus per artist
give a bonus of 0 for others
*/

SELECT art.artistid, art.Name as ArtistName, Bonus, NbSoldTracks
FROM (
    SELECT art.artistid, art.Name, Sum(Quantity) as NbSoldTracks,
    case when art.artistid IN 
        ( 
            SELECT art.artistid
            FROM 
                artists art, 
                albums alb, 
                tracks t, 
                invoice_items ii, 
                invoices i
            WHERE 
                alb.artistid = art.artistid AND
                t.albumid = alb.albumid AND
                ii.trackid = t.trackid AND
                i.invoiceid = ii.invoiceid 
            GROUP BY art.artistid
            HAVING sum(ii.quantity) > 10
        ) 
    then (SUM(Milliseconds) /1000 / 100 * 0.15) 
    else 0 end 
    as Bonus
FROM 
    tracks t,
    albums alb,
    artists art,
    invoice_items ii
WHERE 
    alb.albumid = t.albumid AND
    art.artistid = alb.artistid AND
    ii.trackid = t.trackid AND
    t.trackid IN (SELECT trackid from invoice_items where quantity >=1)
GROUP BY art.artistid 
    )
ORDER BY Bonus DESC
;
    /*6*/

/*
Query 1 : select tracks sold at least once
2 : compute nb tracks per media type
Average per media type
*/

SELECT mt.Name as MediaType, Avg(ii.UnitPrice) as AvgPrice, Count (*) as NbTracks
FROM media_types mt, tracks t, invoice_items ii
WHERE 
    t.mediatypeid = mt.mediatypeid AND
    ii.trackid = t.trackid AND
    t.trackid IN (SELECT trackid from invoice_items where quantity >=1)
GROUP BY mt.mediatypeid
;

    /*7*/

/*
Query 1 : Artists with 2+ genres

*/

CREATE TABLE Versatility_Rank AS
SELECT art.Name as ArtistName, Count(distinct t.genreid) as Versatility
FROM artists art, albums alb, tracks t, genres g
WHERE 
    alb.artistid = art.artistid AND
    t.albumid = alb.albumid AND
    g.genreid = t.genreid
GROUP BY art.artistid 
HAVING Versatility >=2
ORDER BY Versatility DESC

;
select * from Versatility_Rank
;
drop table Versatility_Rank
;
    /*8*/

/*
Query 1 : case when to create the type column
group by type, e.lastname
*/

SELECT e.lastname as Lastname,
    CASE WHEN c.company is null
        THEN 'Regular'
        ELSE 'Company'
    END as Type,
        Count(distinct i.customerid) as 'Number of customers', Sum(i.Total) as 'Total sales'
FROM customers c, employees e, invoices i
WHERE e.employeeid = c.supportrepid AND
    i.customerid = c.customerid
GROUP BY type, e.Lastname
ORDER BY 1
;