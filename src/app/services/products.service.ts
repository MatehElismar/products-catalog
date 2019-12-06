import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Product } from '../models/product.model';
import { map } from 'rxjs/operators'

@Injectable({
  providedIn: 'root'
})
export class ProductsService {

  constructor(private http: HttpClient) { }

  getProducts(){ 
    return this.http.get<Product[]>('https://hamburgerapi.azurewebsites.net/api/products')

  }

  getProduct(id:string){
    return this.http.get<Product[]>('https://hamburgerapi.azurewebsites.net/api/products')
    .pipe(
      map(products => products.filter(produc => produc.id == id)[0])
    )

  }

  addProduct(product : Product){
    return this.http.post('https://hamburgerapi.azurewebsites.net/api/products', product)
  }
}
