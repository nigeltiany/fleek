enum SearchInterest {
  DATES,
  FRIENDS,
  ROOMMATES,
}

extension SearchInterestToString on SearchInterest {
  String toFirebaseString() {
    return this.toString().split('.').last;
  }
}

SearchInterest searchInterestFromFirebaseString(String pref) {
  for (SearchInterest option in SearchInterest.values) {
    if (option.toFirebaseString() == pref) {
      return option;
    }
  }
  return SearchInterest.DATES;
}