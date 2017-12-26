alter table spectrum.sales_part
add partition(saledate='2008-01-01') 
location 's3://awssampledbuswest2/tickit/spectrum/sales_partition/saledate=2008-01/';
alter table spectrum.sales_part
add partition(saledate='2008-02-01') 
location 's3://awssampledbuswest2/tickit/spectrum/sales_partition/saledate=2008-02/';
alter table spectrum.sales_part
add partition(saledate='2008-03-01') 
location 's3://awssampledbuswest2/tickit/spectrum/sales_partition/saledate=2008-03/';
alter table spectrum.sales_part
add partition(saledate='2008-04-01') 
location 's3://awssampledbuswest2/tickit/spectrum/sales_partition/saledate=2008-04/';
alter table spectrum.sales_part
add partition(saledate='2008-05-01') 
location 's3://awssampledbuswest2/tickit/spectrum/sales_partition/saledate=2008-05/';
alter table spectrum.sales_part
add partition(saledate='2008-06-01') 
location 's3://awssampledbuswest2/tickit/spectrum/sales_partition/saledate=2008-06/';
alter table spectrum.sales_part
add partition(saledate='2008-07-01') 
location 's3://awssampledbuswest2/tickit/spectrum/sales_partition/saledate=2008-07/';
alter table spectrum.sales_part
add partition(saledate='2008-08-01') 
location 's3://awssampledbuswest2/tickit/spectrum/sales_partition/saledate=2008-08/';
alter table spectrum.sales_part
add partition(saledate='2008-09-01') 
location 's3://awssampledbuswest2/tickit/spectrum/sales_partition/saledate=2008-09/';
alter table spectrum.sales_part
add partition(saledate='2008-10-01') 
location 's3://awssampledbuswest2/tickit/spectrum/sales_partition/saledate=2008-10/';
alter table spectrum.sales_part
add partition(saledate='2008-11-01') 
location 's3://awssampledbuswest2/tickit/spectrum/sales_partition/saledate=2008-11/';
alter table spectrum.sales_part
add partition(saledate='2008-12-01') 
location 's3://awssampledbuswest2/tickit/spectrum/sales_partition/saledate=2008-12/';
