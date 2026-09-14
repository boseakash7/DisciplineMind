import 'package:discipline_mind/controller/alert_controller.dart';
import 'package:discipline_mind/ui/main_home/set_alert.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../model/instrument_api_model.dart';

class SearchStockScreen extends StatelessWidget {
  SearchStockScreen({super.key});

  final AlertController controller = Get.put(AlertController());
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: const Text("Search Stocks"),
        actions: [
          TextButton(
            onPressed: () {
              searchController.clear();
              controller.fetchInstruments(""); // reset search
            },
            child: const Text("Clear"),
          ),
        ],
      ),
      body: Column(
        children: [
          _searchBar(),
          // _tabs(),
          Expanded(child: _stockList()),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: searchController,
          onChanged: (value) => controller.fetchInstruments(value),
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: "Search stocks, ETFs, MF",
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _tabs() {
    final tabs = ["#", "MF", "IPO", "Events", "Brands", "ETF"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              tab,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _stockList() {
    return Obx(() {
      if (controller.isLoading.value) {
        // Shimmer loading
        return ListView.builder(
          itemCount: 6,
          itemBuilder: (_, __) => _shimmerTile(),
        );
      }

      if (controller.instruments.isEmpty) {
        return const Center(child: Text("No results found"));
      }

      return ListView.separated(
        itemCount: controller.instruments.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final stock = controller.instruments[index];
          return _stockTile(stock);
        },
      );
    });
  }

  Widget _stockTile(Payload stock) {
    final isNSE = stock.exchange == "NSE";

    return ListTile(
      leading: _exchangeTag(stock.exchange!),
      title: Text(
        stock.tradingsymbol ?? "",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        stock.name ?? "",
        style: TextStyle(color: Colors.grey.shade600),
      ),
      trailing: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue),
          borderRadius: BorderRadius.circular(6),
        ),
        child: IconButton(
          icon: const Icon(Icons.add, color: Colors.blue),
          onPressed: () {
            Get.to(() => SetAlertDetailScreen(stock: stock));
          },
        ),
      ),
    );
  }

  Widget _exchangeTag(String exchange) {
    final isNSE = exchange == "NSE";

    return Container(
      width: 42,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isNSE
            ? Colors.red.withOpacity(0.12)
            : Colors.blue.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        exchange,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isNSE ? Colors.red : Colors.blue,
        ),
      ),
    );
  }

  Widget _shimmerTile() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListTile(
        leading: Container(width: 42, height: 28, color: Colors.white),
        title: Container(
          height: 16,
          color: Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 4),
        ),
        subtitle: Container(
          height: 12,
          color: Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 4),
        ),
        trailing: Container(width: 32, height: 32, color: Colors.white),
      ),
    );
  }
}
