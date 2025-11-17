import { Component, inject, OnInit, OnDestroy } from '@angular/core';
import { RegisterComponent } from "../register/register.component";
import { HttpClient } from '@angular/common/http';
import { RouterModule } from '@angular/router';
import { HomeStateService } from '../_services/home-state.service';
import { Subscription } from 'rxjs';

@Component({
  selector: 'app-home',
  imports: [RegisterComponent, RouterModule],
  templateUrl: './home.component.html',
  styleUrl: './home.component.css'
})
export class HomeComponent implements OnInit, OnDestroy {
  private homeStateService = inject(HomeStateService);
  private resetSubscription?: Subscription;
  registerMode = false;
  users: any;

  ngOnInit() {
    this.resetSubscription = this.homeStateService.resetHome$.subscribe(() => {
      this.registerMode = false;
      window.scrollTo({ top: 0, behavior: 'smooth' });
    });
  }

  ngOnDestroy() {
    this.resetSubscription?.unsubscribe();
  }

  registerToggle(){
    this.registerMode = !this.registerMode;
  }

  cancelRegisterMode(event: boolean){
    this.registerMode = event;
  }

}
