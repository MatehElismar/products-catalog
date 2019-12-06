import { Component, OnInit } from '@angular/core';
import { Product } from 'src/app/models/product.model';
import { ProductsService } from 'src/app/services/products.service';
import { ActivatedRoute } from '@angular/router';

@Component({
  selector: 'app-product-detail',
  templateUrl: './product-detail.page.html',
  styleUrls: ['./product-detail.page.scss'],
})
export class ProductDetailPage implements OnInit {

  product: Product
  constructor(private productsService: ProductsService, private route: ActivatedRoute) {
    this.product = {
      id: "-1",
      name : '',
      image : '',
      price : 2
    }
   }

  ngOnInit() {
    this.route.paramMap.subscribe(paramMap => {
      const productId = paramMap.get('id')
      this.productsService.getProduct(productId)
        .subscribe(
        product => this.product = product
      )
    })
  }

}
