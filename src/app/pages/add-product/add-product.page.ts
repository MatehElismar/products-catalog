import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup } from '@angular/forms';
import { ProductsService } from 'src/app/services/products.service';

@Component({
  selector: 'app-add-product',
  templateUrl: './add-product.page.html',
  styleUrls: ['./add-product.page.scss'],
})
export class AddProductPage implements OnInit {
  form: FormGroup
  constructor(fb: FormBuilder, private productsService: ProductsService) {
    this.form = fb.group({
      name : [null],
      image : [null],
      price : [null]
    })

    this.form.valueChanges.subscribe(console.log)
  }

  ngOnInit() {
    
  }

  add() {
    this.productsService.addProduct(this.form.value)
    .subscribe(console.log)
  }

}
