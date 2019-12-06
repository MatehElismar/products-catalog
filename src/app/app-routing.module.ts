import { NgModule } from '@angular/core';
import { PreloadAllModules, RouterModule, Routes } from '@angular/router';


const routes: Routes = [
  {
    path: '',
    redirectTo: 'products',
    pathMatch: 'full'
  },
  {
    path: 'products',
    children : [
      {
        path : '',
        loadChildren: () => import('./pages/products/products.module').then(m => m.ProductsPageModule),
      },
      {
        path: 'new',
        loadChildren: () => import('./pages/add-product/add-product.module').then( m => m.AddProductPageModule)
      },
      {
        path: ':id',
        loadChildren: () => import('./pages/product-detail/product-detail.module').then( m => m.ProductDetailPageModule)
      },
    ]
  }, 
];

@NgModule({
  imports: [
    RouterModule.forRoot(routes, { preloadingStrategy: PreloadAllModules })
  ],
  exports: [RouterModule]
})
export class AppRoutingModule {}
