import { Component, inject, OnInit } from '@angular/core';
import { NavComponent } from "./nav/nav.component";
import { AccountService } from './_services/accounts.service';
import { HomeComponent } from "./home/home.component";
import { RouterOutlet } from '@angular/router';
import { NgxSpinner, NgxSpinnerComponent } from 'ngx-spinner';
import { ScrollToTopComponent } from './scroll-to-top/scroll-to-top.component';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, NavComponent, NgxSpinnerComponent, ScrollToTopComponent],
  templateUrl: './app.component.html',
  styleUrl: './app.component.css'
})
export class AppComponent implements OnInit{
  private accountService = inject(AccountService);
  

  ngOnInit(): void {
      this.setCurrentUser();
  }

  setCurrentUser(){
    const userString = localStorage.getItem('user');
    if(!userString) return;
    const user = JSON.parse(userString);
    // this.accountService.currentUser.set(user);
    this.accountService.setCurrentUser(user);
  }
}
