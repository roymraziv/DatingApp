import { Component, inject, OnInit, HostListener, ElementRef } from '@angular/core';
import { Member } from '../../_models/member';
import { MembersService } from '../../_services/members.service';
import { MemberCardComponent } from "../member-card/member-card.component";
import { PaginationModule } from 'ngx-bootstrap/pagination';
import { AccountService } from '../../_services/accounts.service';
import { UserParams } from '../../_models/userParams';
import { FormsModule } from '@angular/forms';
import { ButtonsModule } from 'ngx-bootstrap/buttons';

@Component({
  selector: 'app-member-list',
  imports: [MemberCardComponent, PaginationModule, FormsModule, ButtonsModule],
  templateUrl: './member-list.component.html',
  styleUrl: './member-list.component.css'
})
export class MemberListComponent implements OnInit {
  memberService = inject(MembersService);
  private elementRef = inject(ElementRef);
  // private accountService = inject(AccountService);
  // userParams = new UserParams(this.accountService.currentUser());
  genderList =[{value: 'male', display: 'Males'}, {value:'female', display: 'Females'}]

  // Pull to refresh properties
  isPulling = false;
  pullStartY = 0;
  pullDistance = 0;
  isRefreshing = false;


  loadMembers() {
    this.memberService.getMembers();
  }

  resetFilters() {
    this.memberService.resetUserParams();
    this.loadMembers();
  }

  ngOnInit(): void {
    if(!this.memberService.paginatedResult()) this.loadMembers();
  }

  pageChanged(event: any) {
    if(this.memberService.userParams().pageNumber != event.page){
      this.memberService.userParams().pageNumber = event.page;
      this.loadMembers();
    }
  }

  // Pull to refresh handlers
  @HostListener('touchstart', ['$event'])
  onTouchStart(event: TouchEvent): void {
    // Only activate if at top of page
    if (window.scrollY === 0) {
      this.pullStartY = event.touches[0].clientY;
      this.isPulling = true;
    }
  }

  @HostListener('touchmove', ['$event'])
  onTouchMove(event: TouchEvent): void {
    if (!this.isPulling || this.isRefreshing) return;

    const currentY = event.touches[0].clientY;
    this.pullDistance = Math.max(0, (currentY - this.pullStartY) / 2);

    // Limit pull distance
    if (this.pullDistance > 100) {
      this.pullDistance = 100;
    }

    // Prevent default scroll if pulling
    if (this.pullDistance > 10 && window.scrollY === 0) {
      event.preventDefault();
    }
  }

  @HostListener('touchend', ['$event'])
  onTouchEnd(event: TouchEvent): void {
    if (!this.isPulling) return;

    // Trigger refresh if pulled far enough
    if (this.pullDistance > 60) {
      this.refreshData();
    }

    this.isPulling = false;
    this.pullDistance = 0;
  }

  refreshData(): void {
    this.isRefreshing = true;

    // Reset to first page and reload
    this.memberService.userParams().pageNumber = 1;
    this.memberService.getMembers();

    // Simulate loading time for smooth UX
    setTimeout(() => {
      this.isRefreshing = false;
    }, 1000);
  }

}
