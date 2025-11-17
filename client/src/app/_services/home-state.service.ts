import { Injectable } from '@angular/core';
import { Subject } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class HomeStateService {
  private resetHomeSubject = new Subject<void>();

  resetHome$ = this.resetHomeSubject.asObservable();

  resetHome() {
    this.resetHomeSubject.next();
  }
}
