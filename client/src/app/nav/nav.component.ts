import { Component, inject, HostListener, ElementRef } from '@angular/core';
import { FormsModule } from '@angular/forms'
import { AccountService } from '../_services/accounts.service';
import { BsDropdownModule } from 'ngx-bootstrap/dropdown';
import { Router, RouterLink, RouterLinkActive } from '@angular/router';
import { ToastrService } from 'ngx-toastr';
import { HasRoleDirective } from '../_directives/has-role.directive';
import { HomeStateService } from '../_services/home-state.service';

@Component({
  selector: 'app-nav',
  imports: [RouterLink, FormsModule, BsDropdownModule, RouterLinkActive, HasRoleDirective],
  templateUrl: './nav.component.html',
  styleUrl: './nav.component.css'
})
export class NavComponent {
  accountService = inject(AccountService);
  private router = inject(Router);
  private toastr = inject(ToastrService);
  private homeStateService = inject(HomeStateService);
  private elementRef = inject(ElementRef);
  model: any = {};
  isCollapsed = true;

  login(){
    this.accountService.login(this.model).subscribe({
      next: response => {
        console.log(response);
        this.router.navigateByUrl('/members');
      },
      error: error => this.toastr.error(error.error)
    });
  }

  logout(){
    this.accountService.logout();
    this.router.navigateByUrl('/');
  }

  goHome(){
    this.router.navigateByUrl('/').then(() => {
      this.homeStateService.resetHome();
    });
    this.closeMenu();
  }

  toggleCollapse(){
    this.isCollapsed = !this.isCollapsed;
  }

  closeMenu(){
    this.isCollapsed = true;
  }

  @HostListener('document:click', ['$event'])
  onDocumentClick(event: MouseEvent): void {
    const clickedInside = this.elementRef.nativeElement.contains(event.target);

    // If menu is open and click is outside the navbar, close it
    if (!this.isCollapsed && !clickedInside) {
      this.isCollapsed = true;
    }
  }
}
