/*
   This file is part of the BOLT-LMM linear mixed model software package
   developed by Po-Ru Loh.  Copyright (C) 2014-2018 Harvard University.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <vector>
#include <string>
#include <cstdlib>
#include <cstdio>
#include <iostream>
#include <sstream>

#include "StringUtils.hpp"

namespace StringUtils {
  using std::vector;
  using std::string;
  using std::cout;
  using std::cerr;
  using std::endl;

  int stoi(const string &s) {
    int i;
    if (sscanf(s.c_str(), "%d", &i) == 0) {
      cerr << "ERROR: Could not parse integer from string: " << s << endl;
      exit(1);
    }
    return i;
  }
  double stod(const string &s) {
    double d;
    sscanf(s.c_str(), "%lf", &d);
    return d;
  }
  string itos(int i) {
    std::ostringstream oss;
    oss << i;
    return oss.str();
  }
  string findDelimiters(const string &s, const string &c) {
    string delims;
    for (uint16_t p = 0; p < s.length(); p++)
      if (c.find(s[p], 0) != string::npos)
	delims += s[p];
    return delims;
  }
  // will not return blanks
  vector <string> tokenizeMultipleDelimiters(const string &s, const string &c)
  {
    uint16_t p = 0;
    vector <string> ans;
    string tmp;
    while (p < s.length()) {
      tmp = "";
      while (p < s.length() && c.find(s[p], 0) != string::npos)
	p++;
      while (p < s.length() && c.find(s[p], 0) == string::npos) {
	tmp += s[p];
	p++;
      }
      if (tmp != "")
	ans.push_back(tmp);
    }
    return ans;
  }

  void rangeErrorExit(const string &str, const string &delims) {
    cerr << "ERROR: Invalid delimiter sequence for specifying range: " << endl;
    cerr << "  Template string: " << str << endl;
    cerr << "  Delimiter sequence found: " << delims << endl;
    cerr << "Range in must have format {start:end} with no other " << RANGE_DELIMS
	 << " chars" << endl;
    exit(1);
  }
  
  // basic range template: expand "{start:end}" to vector <string> with one entry per range element
  // if end==start-1, will return empty
  vector <string> expandRangeTemplate(const string &str) {
    vector <string> ret;
    string delims = findDelimiters(str, RANGE_DELIMS);
    if (delims.empty())
      ret.push_back(str);
    else if (delims == RANGE_DELIMS) {
      vector <string> tokens = tokenizeMultipleDelimiters(str, RANGE_DELIMS);
      for (int i = 0; i < (int) str.size(); i++)
	if (str[i] == ':' && (str[i-1] == '{' || str[i+1] == '}'))
	  rangeErrorExit(str, delims);
      int startInd = (str[0] != RANGE_DELIMS[0]), endInd = startInd+1;
      string prefix, suffix;
      if (str[0] != RANGE_DELIMS[0]) prefix = tokens[0];
      if (str[str.length()-1] != RANGE_DELIMS[2]) suffix = tokens.back();
      int start = StringUtils::stoi(tokens[startInd]), end = StringUtils::stoi(tokens[endInd]);
      if (start > end+1 || end > start+1000000) {
	cerr << "ERROR: Invalid range in template string: " << str << endl;
	cerr << "  Start: " << start << endl;
	cerr << "  End: " << end << endl;
	exit(1);
      }
      for (int i = start; i <= end; i++)
	ret.push_back(prefix + itos(i) + suffix);
    }
    else
      rangeErrorExit(str, delims);
    return ret;
  }
  
  vector <string> expandRangeTemplates(const vector <string> &rangeTemplates) {
    vector <string> expanded;
    for (uint16_t i = 0; i < rangeTemplates.size(); i++) {
      vector <string> range = expandRangeTemplate(rangeTemplates[i]);
      expanded.insert(expanded.end(), range.begin(), range.end());
    }
    return expanded;
  }
}
