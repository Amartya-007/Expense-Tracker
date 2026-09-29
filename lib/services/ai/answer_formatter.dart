import 'package:expensetracker/services/ai/query_executor.dart';
import 'package:expensetracker/services/ai/query_spec.dart';
import 'package:expensetracker/utils/currency_formatter.dart';

class AnswerFormatter {
  static String format(QuerySpec spec, QueryExecutionResult result) {
    if (spec.intent == 'balance' || spec.intent == 'budget_status' || spec.intent == 'goal_progress' || spec.intent == 'recurring_bills') {
      return result.summaryText;
    }

    final formattedTotal = CurrencyFormatter.format(result.totalAmount);

    if (spec.intent == 'count') {
      return 'Found ${result.count} matching transaction(s) totaling $formattedTotal.';
    }

    if (spec.intent == 'average') {
      final formattedAvg = CurrencyFormatter.format(result.average);
      return 'The average amount across ${result.count} transaction(s) is $formattedAvg (total: $formattedTotal).';
    }

    if (spec.groupBy != null && result.breakdown.isNotEmpty) {
      final buffer = StringBuffer('Here is the breakdown by ${spec.groupBy}:\n');
      result.breakdown.forEach((key, val) {
        buffer.writeln('• $key: ${CurrencyFormatter.format(val)}');
      });
      buffer.write('\nTotal: $formattedTotal');
      return buffer.toString();
    }

    if (spec.intent == 'list' || spec.sort != null) {
      if (result.transactions.isEmpty) {
        return 'No transactions found matching your query.';
      }
      return 'Here are the matching transactions (total $formattedTotal):';
    }

    // Default sum / breakdown
    if (result.count == 0) {
      return 'No transactions found matching your criteria.';
    }

    String contextStr = '';
    if (spec.categories.isNotEmpty) contextStr += ' on ${spec.categories.join(", ")}';
    if (spec.merchants.isNotEmpty) contextStr += ' at ${spec.merchants.join(", ")}';
    if (spec.tags.isNotEmpty) contextStr += ' with tag #${spec.tags.join(", #")}';

    return 'You spent $formattedTotal$contextStr across ${result.count} transaction(s).';
  }
}
