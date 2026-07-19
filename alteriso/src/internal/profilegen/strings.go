package profilegen

import "sort"

func uniqueStrings(values []string) []string {
	seen := make(map[string]struct{}, len(values))
	result := make([]string, 0, len(values))
	for _, value := range values {
		if _, ok := seen[value]; ok {
			continue
		}
		seen[value] = struct{}{}
		result = append(result, value)
	}
	return result
}

func sortedUniqueStrings(values []string) []string {
	result := uniqueStrings(values)
	sort.Strings(result)
	return result
}
